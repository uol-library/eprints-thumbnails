# IIIF Manifest export plugin

This plugin is intended to produce IIIF manifests from eprint records.

It is based on the work carried out here:

https://github.com/eprintsug/iiif-manifest

However, considerable changes needed to be made and as the use case is limited.

This plugin is only intended to expose a single thumbnail (`lightbox`) for images, or an MP3 file (`audio_mp3`) for audio files - its main purpose is to expose the order and URLs of thumbnails to prevent the system it feeds from guessing(!).

