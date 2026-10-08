# OnePlus Ace 2 Pro (PJA110) Kernel Build Suite

Полный монорепозиторий ядра Linux 5.15 (Android 13 GKI) для **OnePlus Ace 2 Pro** (Qualcomm Snapdragon 8 Gen 2 / SM8550 / `kalama`).

Включает в себя предпропатченные исходники ядра (`common/`), автоматизированный скрипт компиляции (`make.sh`) и AnyKernel3-шаблон для создания готовых к прошивке ZIP-архивов.

---

## Возможности
- **Поддержка Root решений**: SukiSU Ultra, KernelSU, KernelSU Next, ReSukiSU Ultra, YukiSU, More KernelSU, BakaSU, RKSU, KernelSU Lite, WildSU, SakiSU, ApexSU.
- **Интеграция аддонов**: 
  - **SusFS v2.3.0** (полное скрытие рута и маунтов).
  - **ZeroMount v2.0** (нативный VFS-режим).
- **Подсистемы и модули**: 
  - `CONFIG_UDMABUF=y` + VirtIO (стабильность графики SM8550 и поддержка VM).
- **Сетевые и файловые оптимизации**: 
  - TCP BBR (алгоритм контроля перегрузки Google).
  - NTFS3 (нативный быстрый драйвер Paragon).
  - Btrfs (файловая система нового поколения).
- **Авто-скачивание Clang**: Если компилятор AOSP Clang отсутствует, скрипт автоматически скачивает официальный `llvm-r450784` напрямую с серверов Google AOSP.
- **Автоматическая упаковка**: AnyKernel3 flashable zip с поддержкой Magiskboot и подписи.
- **Автоматическое скачивание APK**: Скачивание актуальных менеджеров рута с релизов GitHub.

---

## Требования для сборки
На Ubuntu / Debian:
```bash
sudo apt update
sudo apt install -y build-essential bc bison flex libssl-dev python3 zip curl git qemu-user
```
*(qemu-user / qemu-arm требуется для автоматической упаковки AnyKernel3 через magiskboot)*.

---

## Быстрый старт

### 1. Клонирование репозитория
```bash
git clone https://github.com/<твой_ник>/<имя_репозитория>.git
cd <имя_репозитория>
```

### 2. Сборка ядра

**Рекомендуемая конфигурация (BakaSU + SusFS + ZeroMount + Extras):**
```bash
./make.sh --bakasu --susfs --zero --extras
```

**Сборка с SukiSU:**
```bash
./make.sh --sukisu --susfs --extras
```

**Чистый сток (без рута, только BBR, NTFS3, Btrfs, UDMABUF):**
```bash
./make.sh --stock --extras
```

**Справка по всем опциям:**
```bash
./make.sh --help
```

---

## Результаты сборки (`out_images/`)
После завершения компиляции в папке `out_images/` создаются:
1. **`AnyKernel3-*.zip`** — установочный архив для прошивки через **KernelFlasher** (на живой системе) или через **TWRP Recovery**.
2. **`ReSukiSU_*.apk`** / **`manager.apk`** — актуальное приложение рут-менеджера.
3. **`ksu_module_susfs_*.zip`** — компаньон-модуль SusFS.
4. **`zeromount-*.zip`** — компаньон-модуль ZeroMount.

---

## Установка на телефон
1. Скопируй `AnyKernel3-*.zip` на телефон.
2. Открой приложение **KernelFlasher** (или зайди в **TWRP**).
3. Выбери архив и прошей.
4. Перезагрузи устройство.
