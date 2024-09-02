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
  version = "git";
    # + lib.optionals build_gtk3_plugin "-gtk3"
    # + lib.optionals build_gtk4_plugin "-gtk4"
    # + lib.optionals build_kde4_plugin "-kde4"
    # + lib.optionals build_kf5_plugin  "-kde5"
    # + lib.optionals build_kf6_plugin  "-kde6"
    # + lib.optionals build_xfce_plugin "-xfce"

  src = fetchFromGitHub {
    owner = "GerbilSoft";
    repo = "rom-properties";
    rev = "82ddbbe6574ba64d12c09229ff275bd9f5ba3f1e";
    hash = "sha256-Xj0xGcA/2hqk0gNLOOrqWxNjWONhH6J3VIF4Up/6NVU=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ]
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
    # GUI Plugins
    ++ lib.optionals build_xfce_plugin [ gtk2 cairo gsound ]
    ++ lib.optionals build_gtk3_plugin [ gtk3 cairo gsound ]
    ++ lib.optionals build_gtk4_plugin [ gtk4 cairo gsound ]
    ++ lib.optionals build_kde4_plugin [ ]
    ++ lib.optionals build_kf5_plugin  [ ]
    ++ lib.optionals build_kf6_plugin  [ qtbase kio kwidgetsaddons kfilemetadata ];
  # ];

  /*
    * All: curl zlib libpng libjpeg-turbo nettle pkgconf tinyxml2 gettext libseccomp
    * Optional decompression: zstd lz4 lzo
    * KDE 5.x: qt5-base qt5-tools extra-cmake-modules kio kwidgetsaddons kfilemetadata
    * XFCE (GTK+ 3.x): glib2 gtk3 cairo gsound
    * GNOME, MATE, Cinnamon: glib2 gtk3 cairo libnautilus-extension gsound
  */

  separateDebugInfo = true;

  cmakeFlags = [
    # (lib.cmakeBool "BUILD_CLI" true)
      # Build the `rpcli` command line program.
      # Already set to "ON" in "cmake/options.cmake" so not too worried about
        # setting it again.

    (lib.cmakeBool "INSTALL_APPARMOR" false)
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
      ++ lib.optionals useTracker [ (lib.cmakeFeature "TRACKER_INSTALL_API_VERSION" "3")]
      # GUI Plugins
      ++ lib.optionals build_gtk3_plugin [ (lib.cmakeOptionType "string" "UI_FRONTENDS" "GTK3") ]
      ++ lib.optionals build_gtk4_plugin [ (lib.cmakeOptionType "string" "UI_FRONTENDS" "GTK4") ]
      ++ lib.optionals build_kde4_plugin [ (lib.cmakeOptionType "string" "UI_FRONTENDS" "KDE4") ]
      ++ lib.optionals build_kf5_plugin  [ (lib.cmakeOptionType "string" "UI_FRONTENDS" "KF5") ]
      ++ lib.optionals build_kf6_plugin  [ (lib.cmakeOptionType "string" "UI_FRONTENDS" "KF6") ]
      ++ lib.optionals build_xfce_plugin [ (lib.cmakeOptionType "string" "UI_FRONTENDS" "XFCE") ];

  patches = [
    ./patches/fix_debug_paths.diff
    ./patches/fix_getdents64_build.diff
    ./patches/fix_rp-stub_symlink.diff
    ./patches/fix_kf6_plugindir.diff
    ./patches/fix_libexec.diff
      # Thank you so much for the help with this, @leo60228!
  ];

  /*
    About "patches":
      "fix_debug_paths.diff" is needed to properly have some correct debug
        paths, due to "cmake"'s weird path issues.
      (See below references for "fix_rp-stub_symlink.diff".)

      "fix_getdents64_build.diff" is needed to properly complete and then run
        the build as it's not being detected automatically.
      (Maybe it's an issue with WSL, though I doubt that?)

      "fix_rp-stub_symlink.diff" is needed to properly symlink
        `result/libexec/rp-thumbnail` to `result/bin/rp-stub` due to the odd
        double-path bug as described in
        https://github.com/NixOS/nixpkgs/issues/144170
          # CMake incorrect absolute include/lib paths tracking issue
        https://github.com/NixOS/nixpkgs/pull/172347 and
          #  cmake: add check-pc-files hook to check broken pc files
        https://github.com/NixOS/nixpkgs/pull/247474
          #  cmake: make check-pc-files hook also check .cmake files
  */

  meta = {
    description = "ROM Properties Page shell extension";
    homepage = "https://github.com/GerbilSoft/rom-properties";
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [  ];
    mainProgram = "rpcli";
    platforms = lib.platforms.all;
  };
}
