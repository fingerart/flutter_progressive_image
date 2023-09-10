# flutter_progressive_image

[![pub package](https://img.shields.io/pub/v/flutter_progressive_image.svg)](https://pub.dartlang.org/packages/flutter_progressive_image)
[![GitHub stars](https://img.shields.io/github/stars/fingerart/flutter_progressive_image)](https://github.com/fingerart/flutter_progressive_image/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/fingerart/flutter_progressive_image)](https://github.com/fingerart/flutter_progressive_image/network)
[![GitHub license](https://img.shields.io/github/license/fingerart/flutter_progressive_image)](https://github.com/fingerart/flutter_progressive_image/blob/main/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/fingerart/flutter_progressive_image)](https://github.com/fingerart/flutter_progressive_image/issues)

Language: English | [中文简体](./README_CN.md)

<br/>

A progressive image widget for flutter.

## Preview

| Progressive                                                     | General                                                 |
|-----------------------------------------------------------------|---------------------------------------------------------|
| ![progressive_image](./arts/progressive_image.gif)              | ![general_image](./arts/general_image.gif)              |
| 📺 [progressive image demo video](./arts/progressive_image.mp4) | 📺 [general image demo video](./arts/general_image.mp4) |

## Supported image formats

- [x] jpeg/jpg
- [ ] png
- [ ] gif

## Usage

```dart
Image(
  image: ProgressiveImage(url),
)
```

## Support parameters

| Parameters  | Optional     | Description            |
|:------------|:-------------|------------------------|
| url         | **Required** | image url              |
| headers     | Optional     | Http headers           |
| imageLoader | Optional     | Low-level image loader |


⚠️[Note] The default `imageLoader` does not support persistent caching
