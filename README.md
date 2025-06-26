# HikingSurvey

A beautiful, privacy-first SwiftUI app for collecting, analyzing, and visualizing opinions about hiking using on-device sentiment analysis.

## Features

- **Survey Collection:** Users can submit their opinions about hiking.
- **Sentiment Analysis:** Uses Apple's NaturalLanguage framework for local sentiment scoring (no data leaves the device).
- **Sentiment Visualization:** Responses are categorized as positive, moderate, or negative, with clear color coding and icons.
- **Confidence Meter:** Each sentiment score is accompanied by a visual confidence bar.
- **Filtering:** Filter responses by sentiment category.
- **Bar Graph & Pie Chart:** Visualize sentiment breakdown over time and in summary.
- **Theming:** Choose from Minimal, Mountain, or Forest themes for a personalized look.
- **Dark Mode:** Fully supports light and dark appearance.
- **Localization:** Available in English, Spanish, and French. Easily extendable to more languages.
- **Onboarding:** Friendly onboarding for first-time users.
- **Privacy:** All analysis is done locally. Your data never leaves your device.
- **Settings:** Quick access to privacy policy and theme selection.
- **Editing & Deletion:** Swipe to delete, long-press to edit, and tap to confirm deletion.
- **Haptics:** Subtle feedback for key actions.

## Screenshots

(Add screenshots here for UI, summary view, and theming.)

## Getting Started

1. **Clone the repository:**
   ```sh
   git clone https://github.com/yourusername/HikingSurvey.git
   cd HikingSurvey
   ```
2. **Open in Xcode:**
   Open `HikingSurvey.xcodeproj` in Xcode 14 or later.
3. **Build & Run:**
   Select a simulator or device and press `Cmd+R`.

## Localization
- All user-facing strings are localized using `Localizable.strings`.
- Supported languages: English (Base), Spanish (`es`), French (`fr`).
- To add a new language, create a new `.lproj/Localizable.strings` file and provide translations.

## Theming
- Users can choose between Minimal, Mountain, and Forest themes.
- The theme affects backgrounds, accent colors, cards, and popup views.

## Privacy
- **All analysis is done locally.**
- **Your data never leaves your device.**
- No network requests or analytics are performed.

## Contribution

1. Fork the repo and create your branch:
   ```sh
   git checkout -b feature/YourFeature
   ```
2. Commit your changes and push:
   ```sh
   git commit -am 'Add new feature'
   git push origin feature/YourFeature
   ```
3. Open a Pull Request.

## License

MIT License. See [LICENSE](LICENSE) for details. 