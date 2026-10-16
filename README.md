# Cinna Travel Book

English | [简体中文](README.zh-CN.md)

Road-trip books for **Android, iOS, and Web**, built from one Flutter codebase. Daily plans, road maps, stays, budgets, notes, and preparation checklists stay together.

[Open the travel books](https://icelemon233.github.io/cinna-travel-book/)

## Using a book

Choose the Jiangxi–Anhui or Tibet guide, then select a route variant. Follow a day, inspect its navigation references and overnight stop, adjust the budget, or mark preparation items. Maps can be filtered by day, zoomed, and saved as PNGs; a full book can be exported as a Chinese PDF or sent to system printing.

Web exports download directly in the browser. Android and iOS exports use the system share sheet.

- Jiangxi–Anhui: 15/16/17-day plans, 12 attractions, charging and overnight energy estimates, and two return-route comparisons.
- Tibet: A/B/C permit scenarios, northern branches, Shenzha/Bangor stays, 48 preparation items, and 14 filterable risks.

Personal notes, budgets, and checklist progress stay on the current device. Use a JSON backup to move them to another device. The Web app also reads the previous site's local notes and checklists without deleting their original storage keys.

Travel data retains its original research dates. Road geometry, driving estimates, prices, parking conditions, and permit scenarios are planning references; recheck current conditions before travelling. Generated Tibet imagery is labelled separately from historical real photographs.

## Development

Use **Flutter 3.47.7 / Dart 3.13.5**. Dependencies are pinned in `pubspec.lock`.

```sh
flutter pub get --enforce-lockfile
flutter run -d chrome
flutter analyze --no-pub
flutter test --no-pub
```

Android builds require the Android SDK and JDK. iOS builds require macOS and Xcode.

```sh
flutter build apk --debug --no-pub
flutter build ios --simulator --debug --no-codesign --no-pub
flutter build ios --release --no-codesign --no-pub
flutter build web --release --no-pub --base-href /cinna-travel-book/ --no-web-resources-cdn --no-wasm-dry-run
node tools/prepare-web.mjs
node tools/serve-web.mjs
```

The built Web preview runs at [localhost:18760/cinna-travel-book](http://localhost:18760/cinna-travel-book/). Hash routes work under GitHub Pages, including links such as `#/book/tibet/itinerary?day=10%2F1`.

## Architecture and verification

Features use MVVM, immutable domain models, abstract repositories, injected platform services, and independent budget/energy calculations. Widgets render state and forward user actions. The app runs Flutter widgets on all three platforms; it does not wrap the retired websites in a WebView.

[Architecture and migration boundaries](docs/architecture.md) · [Chinese guide](README.zh-CN.md)

Tests compare 36 legacy budget cases and cover persistence, safe imports, route gaps, generated PNG/PDF files, navigation, and large-text mobile layouts. The CI builds Android, iOS simulator, unsigned iOS device, and Web artifacts, and runs startup/storage smoke tests in disposable Android and iOS simulators. Device sharing, physical printers, signing, and store distribution require separate real-device verification.

## History and publishing

The histories of `cinna-travel` and `cinna-travel-archive` are retained through merge parents and these branches:

- `archive/static-web-20261017`: the original static site and its Tibet snapshot.
- `archive/react-antd-20260920`: the complete React/Ant Design Tibet source.
- `archive/pre-antd`: the earlier Tibet version.

Migration tooling reads fixed Git commits instead of relying on old checkout directories. Node.js 24 and pnpm 11.25.0 are only needed for these tools:

```sh
pnpm install --frozen-lockfile --ignore-scripts
pnpm verify:assets
```

Pushing `main` publishes Flutter Web after quality checks and all platform builds succeed. `deployment.json` records the source commit and static-file hashes. `pnpm deploy` can inspect or request the current main workflow when GitHub CLI is authenticated.

## Attribution

Map data © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), under ODbL; road routes include OSRM references. Photos retain their authors, licences, and source links. Noto Sans SC is distributed under SIL OFL 1.1, and the bundled PDF.js runtime uses Apache-2.0. Project code remains [MIT-licensed](LICENSE).
