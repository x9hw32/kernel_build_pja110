# OnePlus Ace 2 Pro (PJA110) Kernel Build Suite

Автоматизированный инструмент сборки ядра Android 13 (Linux 5.15) для OnePlus Ace 2 Pro (SM8550 / kalama).

## Возможности
- **Поддержка Root решений**: SukiSU Ultra, KernelSU, KernelSU Next, ReSukiSU Ultra, YukiSU, More KernelSU, BakaSU, RKSU, KernelSU Lite, WildSU, SakiSU, ApexSU.
- **Интеграция аддонов**: SusFS, ZeroMount.
- **Подсистемы и модули**: VirtIO, UDMABUF (стабильность графики SM8550).
- **Сетевые и файловые оптимизации**: TCP BBR, NTFS3 (Paragon), Btrfs.
- **Автоматическая упаковка**: AnyKernel3 flashable zip с поддержкой Magiskboot и подписи.
- **Автоматическое скачивание APK**: Скачивание менеджеров рута с релизов GitHub.

## Использование
```bash
# Базовая сборка BakaSU + SusFS + ZeroMount + Extras
./make.sh --bakasu --susfs --zero --extras

# Сборка SukiSU
./make.sh --sukisu --susfs --extras

# Сборка без рута (чистый сток + фичи)
./make.sh --stock --extras

# Справка по всем ключам
./make.sh --help
```
