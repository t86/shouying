# Bundled Chinese printing font

Noto Sans SC, upstream commit `f8d157532fbfaeda587e826d4cd5b21a49186f7c`:
https://github.com/notofonts/noto-cjk/blob/f8d157532fbfaeda587e826d4cd5b21a49186f7c/Sans/Variable/TTF/Subset/NotoSansSC-VF.ttf

Copyright 2014-2021 Adobe (http://www.adobe.com/), with Reserved Font Name 'Source'.
Distributed under SIL Open Font License 1.1; see OFL.txt and the preserved font name metadata.

This is a local static 400-weight instance generated with fontTools 4.65:

    fonttools varLib.instancer NotoSansSC-VF.ttf wght=400 -o NotoSansSC-Regular.ttf

SHA-256: `3d60be49db567b2f6ef436c1d7e8f423ec3b82f1a04ff197687bbfc5c26674b6`

Bundled so PDF printing does not fetch fonts or send document text to a third-party font service at runtime. The PDF generator embeds only the glyphs used by the document.
