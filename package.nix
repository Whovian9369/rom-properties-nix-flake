{
  lib,
  stdenv,
  cmake,
  ninja,
  curl,
  fetchFromGitHub,
  gettext,
  glib,
  libjpeg,
  libpng,
  libseccomp,
  lz4,
  lzo,
  nettle,
  pkg-config,
  pugixml,
  tinyxml-2,
  zlib,
  zstd,

  # Not really required afaik, but I like quieting the warnings :)
  pcre2,
  minizip-ng,
  lerc,
  libcanberra_kde,
  libselinux,
  libsepol,
  libsysprof-capture,
  util-linux,
  inih,

  # Enable GNOME "Tracker".
  useTracker ? false,
  tinysparql,

  # Enable AppArmor rules
  useAppArmor ? false,
  # libapparmor,

  # Build GUI Plugins
  ## Pre-requisites for multiple plugins
  fmt ? null,

  # XFCE (GTK 2.x, GTK 3.x, and GTK 4.x)
  # build_xfce_plugin ? false,
  # gtk2 ? null,

  ## XFCE (GTK+ 3.x)
  build_gtk3_plugin ? false,
  gtk3 ? null,
  xfce ? null,
    # Can't just pull xfce.tumbler directly.
  cairo ? null,
  gsound ? null,
  extra-cmake-modules ? null,
  libcanberra-gtk3 ? null,
  gobject-introspection ? null,
  pango ? null,

  ## XFCE (GTK+ 4.x)?
  build_gtk4_plugin ? false,
  gtk4 ? null,

  ## KDE6
  build_kf6_plugin ? false,
  qt6 ? null,
  kio ? null,
  # extra-cmake-modules ? null,
  kwidgetsaddons ? null,
  kfilemetadata ? null,
  # wrapQtAppsHook ? null,
}:

stdenv.mkDerivation {
  pname = "rom-properties";
  version = "unstable-2025-09-14"
    + lib.optionalString build_gtk3_plugin "-gtk3"
    + lib.optionalString build_gtk4_plugin "-gtk4"
    + lib.optionalString build_kf6_plugin  "-kde6"
  ;

  src = fetchFromGitHub {
    owner = "GerbilSoft";
    repo = "rom-properties";
    rev = "ed761b37e165bb83f8d48ded46fc9b90f5f85eb3";
    hash = "sha256-MIObxua33UFDSLtx5ShzrrVyAbHF3k4dvN+rLAzyhec=";
  };

  dontWrapQtApps = true;

  preConfigure = lib.optionals build_gtk3_plugin ''
    mkdir -p ${placeholder "out"}/lib/glib-2.0/include
  '';

  # Plugin Coverage notes:
    # GTK 3 - MATE, Cinnamon, and XFCE
      /*
        MATE (Caja):
          - Thumbnails
          - Has "Properties" tab

        Cinnamon (Nemo):
          - Thumbnails
          - No "Properties" tab

        XFCE (Thunar):
          - Thumbnails
          - Has "Properties" tab
      */

    # GTK 4 - GNOME
      /*
        GNOME (Nautilus)
          - Notes to self:
            - Uses "$out/lib/nautilus/extensions-4" for plugins
              - nixpkgs:/nixos/modules/services/x11/desktop-managers/gnome.nix
            - Check out pkgs/desktops/gnome/extensions/buildGnomeExtension.nix
          - ?
          - ?
      */

    # KDE 6 / Plasma 6
      /*
        Plasma 6:
          - Thumbnails
          - Has "Properties" tab
      */

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    pugixml
  ]
    # GTK3
    ++ lib.optionals build_gtk3_plugin  [
      lerc.dev
      gobject-introspection
    ]

    # QT 6 / KDE 6
    ++ lib.optionals build_kf6_plugin  [
      lerc.dev
      extra-cmake-modules
    ];

  buildInputs = [
    nettle
    glib
    libselinux
    libsepol
    pcre2
    util-linux
    # curl
    curl.dev
    libjpeg
    libpng
    libseccomp
    lz4
    zlib
    zstd
    gettext
    lzo
    tinyxml-2
    minizip-ng
    inih
    gtk3
    xfce.tumbler
    gsound
    libsysprof-capture
      # Not really required afaik, but I like quieting the warnings :)
    fmt
  ]
    # GNOME Tracker
    ++ lib.optionals useTracker [ tinysparql ]

    # AppArmor
    # ++ lib.optionals useAppArmor [ libapparmor ]

    # GUI Plugins
    # ++ lib.optionals build_xfce_plugin [ gtk2 cairo gsound ]
    ++ lib.optionals build_gtk3_plugin [
      # Also has useTracker set, so uses pkgs.tinysparql
      cairo
      gsound
      xfce.tumbler.dev
      xfce.thunar.dev
      gtk3.dev
      libcanberra-gtk3
      pango.dev
    ]

    # GTK4
    ++ lib.optionals build_gtk4_plugin [
      gtk4
      cairo
      gsound
    ]

    # QT 6 / KDE 6
    ++ lib.optionals build_kf6_plugin  [
      qt6.qtbase
      kio
      kwidgetsaddons
      kfilemetadata
      libcanberra_kde
    ];

  /* Notes about prerequisites from upstream:

    On Debian/Ubuntu, you will need build-essential and the following development
    packages:
    * All: cmake libcurl-dev zlib1g-dev libpng-dev libjpeg-dev nettle-dev pkg-config libtinyxml2-dev gettext libseccomp-dev libfmt-dev
    * Optional decompression: libzstd-dev liblz4-dev liblzo2-dev
    * KDE 4.x: libqt4-dev kdelibs5-dev
    * KDE 5.x: qtbase5-dev qttools5-dev-tools extra-cmake-modules libkf5kio-dev libkf5widgetsaddons-dev libkf5filemetadata-dev libkf5crash-dev
    * KDE 6.x: qt6-base-dev qt6-tools-dev-tools extra-cmake-modules libkf6kio-dev libkf6widgetsaddons-dev libkf6filemetadata-dev libkf6crash-dev
    * XFCE (GTK+ 2.x): libglib2.0-dev libgtk2.0-dev libgdk-pixbuf2.0-dev libthunarx-2-dev libcanberra-dev libgsound-dev
    * XFCE (GTK+ 3.x): libglib2.0-dev libgtk-3-dev libcairo2-dev libthunarx-3-dev libgsound-dev
    * GNOME, MATE, Cinnamon: libglib2.0-dev libgtk-3-dev libcairo2-dev libnautilus-extension-dev libgsound-dev
    * GNOME 43: libglib2.0-dev libgtk-4-dev libgdk-pixbuf2.0-dev libnautilus-extension-dev libgsound-dev

    ===========================================================================

    src/libunixcommon/dll-search.c:
    ```
    // Supported rom-properties frontends.
    typedef enum {
      RP_FE_KDE4,
      RP_FE_KF5,
      RP_FE_KF6,
      RP_FE_GTK2, // XFCE (Thunar 1.6)
      RP_FE_GTK3, // GNOME, MATE, Cinnamon, XFCE (Thunar 1.8)
      RP_FE_GTK4, // GNOME 43

      RP_FE_MAX
    } RP_Frontend;
    ```
  */

  separateDebugInfo = true;

  cmakeFlags = [
    # (lib.cmakeBool "BUILD_CLI" true)
    /*
      Build the `rpcli` command line program.
      Already set to `ON` in `cmake/options.cmake` so not too worried about
      setting it again.
    */

    (lib.cmakeBool "INSTALL_APPARMOR" useAppArmor)
      # Required for build since it wants to write to "/etc/apparmor.d"
      # Can I change its directory to technically include it?
      # TODO: Try to fix(?) AppArmor support
    (lib.cmakeBool "ENABLE_DECRYPTION" true)
      # Enable decryption for newer ROM and disc images.
    (lib.cmakeBool "ENABLE_EXTRA_SECURITY" true)
      # Enable extra security functionality if available.
    (lib.cmakeBool "ENABLE_JPEG" true)
      # Enable JPEG decoding using libjpeg.
    (lib.cmakeBool "ENABLE_XML" true)
      # Enable XML parsing for e.g. Windows manifests.
    (lib.cmakeBool "ENABLE_UNICE68" true)
      # Enable UnICE68 for Atari ST SNDH files. (GPLv3)
    (lib.cmakeBool "ENABLE_LIBMSPACK" true)
      # Enable libmspack-xenia for Xbox 360 executables.
    (lib.cmakeBool "ENABLE_PVRTC" true)
      # Enable the PowerVR Native SDK subset for PVRTC decompression.
    (lib.cmakeBool "ENABLE_ZSTD" true)
      # Enable ZSTD decompression. (Required for some unit tests.)
    (lib.cmakeBool "ENABLE_ASTC" true)
      # Enable the ASTC decoder from Basis Universal.
    (lib.cmakeBool "ENABLE_LZ4" true)
      # Enable LZ4 decompression. (Required for some PSP disc formats.)
    (lib.cmakeBool "ENABLE_LZO" true)
      # Enable LZO decompression. (Required for some PSP disc formats.)
    (lib.cmakeBool "ENABLE_NLS" true)
      # Enable NLS. (internationalization)
      # Enable NLS using gettext for localized messages.
    (lib.cmakeBool "ENABLE_OPENMP" true)
      # Enable OpenMP support if available.
    (lib.cmakeBool "SPLIT_DEBUG" false)
      # Let Nix handle the debug files with "separateDebugInfo" instead of
      # letting the normal build process do it.
      # Should prevent duplicate entries in .#default.debug.outpath .
    (lib.cmakeBool "INSTALL_DEBUG" false)
      # Install the split debug files, if those are enabled via "SPLIT_DEBUG".
    (lib.cmakeBool "ENABLE_NIXOS" true)
      # Special handling for NixOS
      /*
        Basically a hack to fix two issues I had made patches for before
        reporting the issues upstream.

        Due to odd path issues, debug file paths were seemingly duplicated
        multiple times in the output path.

        There's also a fix for system calls used, but only appears to be
        required on NixOS?

        Specifics can be found at
        https://github.com/GerbilSoft/rom-properties/commit/adc780f1138a1450fcf98e183253d2a3fa3ce46a
      */

    /*
      # Flags enabled when on Windows
      # Not needed here since we're getting them from Nixpkgs.
      (lib.cmakeBool "USE_INTERNAL_ZLIB" false)
      (lib.cmakeBool "USE_INTERNAL_PNG" false)
      (lib.cmakeBool "USE_INTERNAL_XML" false)
      (lib.cmakeBool "USE_INTERNAL_ZSTD" false)
      (lib.cmakeBool "USE_INTERNAL_LZ4" false)
      (lib.cmakeBool "USE_INTERNAL_LZO" false)
    */
  ]
    # GNOME Tracker
    ++ lib.optionals useTracker [
      (lib.cmakeFeature "TRACKER_INSTALL_API_VERSION" "3")
    ]
    # AppArmor
    ++ lib.optionals useAppArmor [
      (lib.cmakeFeature "DIR_INSTALL_APPARMOR" "${placeholder "out"}/etc/apparmor.d")
    ]
    # GUI Plugins
    ++ lib.optionals build_gtk3_plugin [
      (lib.cmakeFeature "UI_FRONTENDS" "GTK3")
      (lib.cmakeFeature "GTK3_GLIBCONFIG_INCLUDE_DIR" "${placeholder "out"}/lib/glib-2.0/include")
    ]
    ++ lib.optionals build_gtk4_plugin [
      (lib.cmakeFeature "UI_FRONTENDS" "GTK4")
    ]
    /*
    ++ lib.optionals build_kde4_plugin [
      (lib.cmakeFeature "UI_FRONTENDS" "KDE4")
    ]
    */
    ++ lib.optionals build_kf6_plugin  [
      (lib.cmakeFeature "UI_FRONTENDS" "KF6")
      (lib.cmakeFeature "QT_MAJOR_VERSION" "6")
        # Prevents build from trying to force use of QT5 dev libraries
        # ... For some reason?
    /*
    ]
    ++ lib.optionals build_xfce_plugin [
      (lib.cmakeFeature "UI_FRONTENDS" "XFCE")
    */
    ];

  patches = [
    ./patches/fix_libexec.diff
      # Thank you for helping with this patch, @leo60228!
  ]
    ++ lib.optionals useAppArmor [
      ./patches/fix_apparmor_output.diff
    ]

    ++ lib.optionals build_gtk3_plugin [
      ./patches/fix_gtk3_plugindir.diff
        # Fix plugin path to not include the full path to $out
    ]

    ++ lib.optionals build_kf6_plugin [
      ./patches/fix_kf6_plugindir.diff
        # Fix plugin path by removing logic to automatically find it.
        # Thank you for helping with this patch, @leo60228!
    ];

  /* About used patches:
    `fix_libexec.diff` fixes where `result/lib/libromdata.so.5.0` looks for
      `rp-download` at runtime. Seems to mainly affect use of the GUI plugin.

    `fix_apparmor_output.diff` lets us override the default output directory
      for AppArmor profiles. This makes it so the build process doesn't try to
      write to an FHS-only directory, and makes it more follow (with the help of
      a CMake flag) the suggested Nix packaging style.

    `fix_kf6_plugindir.diff` fixes the KDE 6 plugin path.
      Makes the build use KDE's `cmake` logic for finding the plugin install
      path instead of doing it manually.
      (Technically it's a Qt thing and not KDE, but this is for KDE so...)
  */

  postInstall = lib.optionals useAppArmor ''
    mv "$out/etc/apparmor.d/"*rp-download "$out/etc/apparmor.d/bin.rp-download"
  '';
  /*
    `mv` required to properly(?) set filename for AppArmor Profile instead of
    the default filename, which included the full nix store path (with full
    stops instead of slashes as path delimiters.) and thus shouldn't be included
    as part of the build. I don't think that the original (full path) filename
    would actually work for AppArmor reasons? I'm not sure, but it seems like
    the smartest idea for me to change it.

    Commit from 2024-03-01 disables the AppArmor rules for `rpcli`
    Supposedly due to the rules possibly blocking proper use in the user's
    `$HOME` directory.
    "It's not allowing writes to the user's home directory, which prevents
    extracting images."
    More information can be found on the relevant commit message.
    GerbilSoft/rom-properties/commit/ff6c90736d1d598be54bafccb12f590e0ff3e905
  */

  meta = {
    description = "ROM Properties Page shell extension"
      + lib.optionalString build_gtk3_plugin " (GTK3)"
      + lib.optionalString build_gtk4_plugin " (GTK4)"
      # + lib.optionalString build_kde4_plugin " (KDE4)"
      + lib.optionalString build_kf6_plugin  " (KDE6)"
      # + lib.optionalString build_xfce_plugin " (XFCE)"
      ;

    homepage = "https://github.com/GerbilSoft/rom-properties";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [  ];
    mainProgram = "rpcli";
    platforms = lib.platforms.all;
  };
}
