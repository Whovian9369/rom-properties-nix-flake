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
  libselinux,
  libsepol,
  util-linux,
  inih,

  # Enable GNOME "Tracker".
  useTracker ? false,
  tracker,

  # Enable AppArmor rules
  useAppArmor ? false,
  # libapparmor,

  # Build GUI Plugins
  build_xfce_plugin ? false,
  xfce, # Can't just pull xfce.tumbler directly.
  gtk2,
  cairo,
  gsound,

  ## XFCE (GTK+ 3.x)
  build_gtk3_plugin ? false,
  gtk3,
  # xfce, # Can't just pull xfce.tumbler directly.
  # cairo,
  # gsound,

  ## XFCE (GTK+ 4.x)?
  build_gtk4_plugin ? false,
  gtk4,
  # xfce, # Can't just pull xfce.tumbler directly.
  # cairo,
  # gsound,

  build_kde4_plugin ? false,
  # KDE4


  build_kf5_plugin ? false,
  # KDE5


  build_kf6_plugin ? false,
  # KDE6
  qtbase ? null,
  kio ? null,
  kwidgetsaddons ? null,
  kfilemetadata ? null,
  wrapQtAppsHook ? null,

}:

stdenv.mkDerivation {
  pname = "rom-properties";
  version = "unstable-2025-01-14"
    + lib.optionalString build_gtk3_plugin "-gtk3"
    + lib.optionalString build_gtk4_plugin "-gtk4"
    + lib.optionalString build_kde4_plugin "-kde4"
    + lib.optionalString build_kf5_plugin  "-kde5"
    + lib.optionalString build_kf6_plugin  "-kde6"
    + lib.optionalString build_xfce_plugin "-xfce";

  src = fetchFromGitHub {
    owner = "GerbilSoft";
    repo = "rom-properties";
    rev = "9adda4bf15219f7f5bb073e762b44de8b7ecc39b";
    hash = "sha256-wS8npb1dL+DvoPloMVV/ott8Tj9+0UU5hBrIsS0ZqBc=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ]
    # KDE 6
    ++ lib.optionals build_kf6_plugin  [ wrapQtAppsHook ];

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
    ++ lib.optionals build_kf5_plugin  [ ]
    ++ lib.optionals build_kf6_plugin  [
      qtbase
      kio
      kwidgetsaddons
      kfilemetadata
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
  */

  separateDebugInfo = true;

  /*
    outputs = [
    "out"
    # "debug"
      # Set by "separateDebugInfo = true;"?
      # Setting it here again errors
        # error: duplicate derivation output 'debug'
      # It's an output, so I'm leaving it listed here.
    ] ++ lib.optionals useAppArmor [ "apparmor" ];
  */

  cmakeFlags = [
    # (lib.cmakeBool "BUILD_CLI" true)
      # Build the `rpcli` command line program.
      # Already set to `ON` in `cmake/options.cmake` so not too worried about
      # setting it again.

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
        # Basically a hack to fix two issues I had made patches for before
        # reporting the issues upstream.

        # Due to odd path issues, debug file paths were seemingly duplicated
        # multiple times in the output path.

        # There's also a fix for system calls used, but only appears to be
        # required on NixOS?

        # Specifics can be found at
        # https://github.com/GerbilSoft/rom-properties/commit/adc780f1138a1450fcf98e183253d2a3fa3ce46a

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
      ]
      ++ lib.optionals build_kf6_plugin  [
        (lib.cmakeFeature "UI_FRONTENDS" "KF6")
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
    ];

  /*
    About used patches:
      `fix_kf6_plugindir.diff` fixes the KDE 6 plugin path.
        Makes the build use KDE's `cmake` logic for finding the plugin install
        path instead of doing it manually.
        (Technically it's a Qt thing and not KDE, but this is for KDE so...)

      `fix_libexec.diff` fixes where `result/lib/libromdata.so.5.0` looks for
        `rp-download` at runtime. Seems to mainly affect use of the GUI plugin.
  */

  postInstall = lib.optionals useAppArmor ''
    mv "$out/etc/apparmor.d/"*rp-download "$out/etc/apparmor.d/bin.rp-download"
    echo "Moved profile for rp-download"
    # mv "$out/etc/apparmor.d/"*rpcli "$out/etc/apparmor.d/bin.rpcli"
    # echo "Moved profile for rpcli"
  '';
  /*
    postInstall = lib.optionals useAppArmor ''
      mv "$out/etc/apparmor.d/"*rpcli "$out/etc/apparmor.d/bin.rpcli"
      echo "Moved profile for rpcli"
    '';
    # For some reason there isn't an `rpcli` file copied over by `INSTALL_APPARMOR`?

    $  fd --type=f apparmor
    src/rp-download/rp-download.apparmor.conf
    src/rpcli/rpcli.apparmor.conf
    src/rpcli/rpcli.local.apparmor.conf
      # Likely unneeded?
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
