# homebridge-unifi-protect with ffmpeg-for-homebridge's static ffmpeg (has libfdk_aac, which
# HomeKit audio needs). Built here so the UI does not require internet out to build.
{
  buildNpmPackage,
  fetchFromGitHub,
  fetchurl,
}:
let
  ffmpeg = fetchurl {
    url = "https://github.com/homebridge/ffmpeg-for-homebridge/releases/download/v2.2.2/ffmpeg-alpine-aarch64.tar.gz";
    hash = "sha256-PtFyRTOSG2tU0f01gCr2Kr0p6GcuCvuUuy+MGBWDI6M=";
  };
in
buildNpmPackage (finalAttrs: {
  pname = "homebridge-unifi-protect";
  version = "8.2.2";
  src = fetchFromGitHub {
    owner = "hjdhjd";
    repo = "homebridge-unifi-protect";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Xe9DXaZu+u3rHMGFQJ2QgntWaS7th9H9YpJdsnWAIxw=";
  };
  npmDepsHash = "sha256-MRkjUJ2udx7iCx7H279sy4Fv05HNHwtfmixcTO0ADZQ=";
  npmRebuildFlags = [ "--ignore-scripts" ]; # ffmpeg-for-homebridge's install script downloads ffmpeg
  # The archive nests ffmpeg at ./usr/local/bin/ffmpeg; the module exports `<its dir>/ffmpeg`.
  postInstall = ''
    tar -xzf ${ffmpeg} --strip-components=4 \
      -C $out/lib/node_modules/homebridge-unifi-protect/node_modules/ffmpeg-for-homebridge \
      ./usr/local/bin/ffmpeg
  '';
})
