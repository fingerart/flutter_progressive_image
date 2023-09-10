# flutter_progressive_image

[![pub package](https://img.shields.io/pub/v/flutter_progressive_image.svg)](https://pub.dartlang.org/packages/flutter_progressive_image)
[![GitHub stars](https://img.shields.io/github/stars/fingerart/flutter_progressive_image)](https://github.com/fingerart/flutter_progressive_image/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/fingerart/flutter_progressive_image)](https://github.com/fingerart/flutter_progressive_image/network)
[![GitHub license](https://img.shields.io/github/license/fingerart/flutter_progressive_image)](https://github.com/fingerart/flutter_progressive_image/blob/main/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/fingerart/flutter_progressive_image)](https://github.com/fingerart/flutter_progressive_image/issues)

语言: [English](./README.md) | 中文简体

<br/>

一个Flutter渐进式图片加载组件。

## 预览

| 渐进式                                                             | 普通                                                      |
|-----------------------------------------------------------------|---------------------------------------------------------|
| ![progressive_image](./arts/progressive_image.gif)              | ![general_image](./arts/general_image.gif)              |
| 📺 [progressive image demo video](./arts/progressive_image.mp4) | 📺 [general image demo video](./arts/general_image.mp4) |

## 支持的图片格式

- [x] jpeg/jpg
- [ ] png
- [ ] gif

## 使用方式

```yaml
dependencies:
  flutter_progressive_image: ^0.0.2
```

```dart
Image(
  image: ProgressiveImage(url),
)
```

## 支持参数

| 参数          | 可选择性   | 说明      |
|:------------|:-------|---------|
| url         | **必选** | 图片路径    |
| headers     | 可选     | Http请求头 |
| imageLoader | 可选     | 图像底层加载器 |


⚠️【注意】默认的`imageLoader`不支持持久化缓存