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
  tracker,

  # Enable AppArmor rules
  useAppArmor ? false,
  # libapparmor,

  # Build GUI Plugins
  ## Pre-requisites for multiple plugins

  # XFCE (XFCE, GTK 3.x, and GTK 4.x)
  xfce ? null,
    # Can't just pull xfce.tumbler directly.
  cairo ? null,
  gsound ? null,


  build_xfce_plugin ? false,
  gtk2,

  ## XFCE (GTK+ 3.x)
  build_gtk3_plugin ? false,
  gtk3,

  ## XFCE (GTK+ 4.x)?
  build_gtk4_plugin ? false,
  gtk4,

  ## KDE4
  build_kde4_plugin ? false,


  ## KDE5
  build_kf5_plugin ? false,
  qt5 ? null,
  libsForQt5 ? null,
  extra-cmake-modules ? null,

  ## KDE6
  build_kf6_plugin ? false,
  qt6 ? null,
  kio ? null,
  kwidgetsaddons ? null,
  kfilemetadata ? null,
  # wrapQtAppsHook ? null,
  fmt ? null,
}:

stdenv.mkDerivation {
  pname = "rom-properties";
  version = "unstable-2025-02-04"
    + lib.optionalString build_gtk3_plugin "-gtk3"
    + lib.optionalString build_gtk4_plugin "-gtk4"
    + lib.optionalString build_kde4_plugin "-kde4"
    + lib.optionalString build_kf5_plugin  "-kde5"
    + lib.optionalString build_kf6_plugin  "-kde6"
    + lib.optionalString build_xfce_plugin "-xfce";

  src = fetchFromGitHub {
    owner = "GerbilSoft";
    repo = "rom-properties";
    rev = "c1e8b097da0b37d89547e4b898b031f6e3e371a4";
    hash = "sha256-DH+TY/azzUQK+EhJnrwuSimgCkQ4WtRIiReqFxsJqwA=";
  };

  dontWrapQtApps = true;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ]
    # KDE 5
    ++ lib.optionals build_kf5_plugin  [
      lerc.dev
      extra-cmake-modules
    ]
    # KDE 6
    ++ lib.optionals build_kf6_plugin  [
      lerc.dev
      # extra-cmake-modules
    ];

  buildInputs = [
    nettle
    glib
    libselinux
    libsepol
    pcre2
    util-linux
    curl
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
  ]
    # GNOME Tracker
    ++ lib.optionals useTracker [ tracker ]

    # AppArmor
    # ++ lib.optionals useAppArmor [ libapparmor ]

    # GUI Plugins
    ++ lib.optionals build_xfce_plugin [ gtk2 cairo gsound ]
    ++ lib.optionals build_gtk3_plugin [ gtk3 cairo gsound ]
    ++ lib.optionals build_gtk4_plugin [ gtk4 cairo gsound ]
    ++ lib.optionals build_kde4_plugin [ ]
    ++ lib.optionals build_kf5_plugin  [
      libsForQt5.qt5.qtbase
      libsForQt5.kwidgetsaddons
      libsForQt5.kio
      libsForQt5.kfilemetadata
        # Error: detected mismatched Qt dependencies
      libcanberra_kde
      fmt
    ]
    ++ lib.optionals build_kf6_plugin  [
      qt6.qtbase
      kio
      kwidgetsaddons
      kfilemetadata
      libcanberra_kde
      fmt
    ];

  /* Notes about prerequisites from upstream:

    * All:
      curl zlib libpng libjpeg-turbo nettle pkgconf tinyxml2 gettext libseccomp

    * Optional decompression:
      zstd lz4 lzo

    * KDE 5.x:
      qt5-base qt5-tools extra-cmake-modules kio kwidgetsaddons kfilemetadata

    * XFCE (GTK+ 3.x):
      glib2 gtk3 cairo gsound

    * GNOME, MATE, Cinnamon:
      glib2 gtk3 cairo libnautilus-extension gsound

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
      ]
      ++ lib.optionals build_gtk4_plugin [
        (lib.cmakeFeature "UI_FRONTENDS" "GTK4")
      ]
      ++ lib.optionals build_kde4_plugin [
        (lib.cmakeFeature "UI_FRONTENDS" "KDE4")
      ]
      ++ lib.optionals build_kf5_plugin  [
        (lib.cmakeFeature "UI_FRONTENDS" "KF5")
        (lib.cmakeFeature "QT_MAJOR_VERSION" "5")
      ]
      ++ lib.optionals build_kf6_plugin  [
        (lib.cmakeFeature "UI_FRONTENDS" "KF6")
        (lib.cmakeFeature "QT_MAJOR_VERSION" "6")
          # Prevents build from trying to force use of QT5 dev libraries
          # ... For some reason?
      ]
      ++ lib.optionals build_xfce_plugin [
        (lib.cmakeFeature "UI_FRONTENDS" "XFCE")
      ];

  patches = [
    ./patches/fix_libexec.diff
      # Thank you for helping with this patch, @leo60228!
  ]
    ++ lib.optionals useAppArmor [
      ./patches/fix_apparmor_output.diff
    ]

    ++ lib.optionals build_kf6_plugin [
      ./patches/fix_kf6_plugindir.diff
        # Fix plugin path by removing logic to automatically find it.
        # Thank you for helping with this patch, @leo60228!
    ]

    ++ lib.optionals build_kf5_plugin [
      ./patches/fix_kf5_plugindir.diff
        # Fix plugin path by removing logic to automatically find it.
        # Based on fix_kf6_plugindir.diff that @leo60228 originally added, so
        # thank you to leo!
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
    as part of the build. Besides, I don't think that the original (full path)
    filename wouldn't actually work for AppArmor reasons? I'm not sure, but it
    seems like the smartest idea for me to change it.

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
      + lib.optionalString build_kde4_plugin " (KDE4)"
      + lib.optionalString build_kf5_plugin  " (KDE5)"
      + lib.optionalString build_kf6_plugin  " (KDE6)"
      + lib.optionalString build_xfce_plugin " (XFCE)";

    homepage = "https://github.com/GerbilSoft/rom-properties";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [  ];
    mainProgram = "rpcli";
    platforms = lib.platforms.all;
  };
}
