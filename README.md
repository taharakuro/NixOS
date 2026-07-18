# nixos-config

Флейк-конфигурация NixOS (niri + noctalia + disko). Собирается как
`nixosConfigurations.nixos`, поэтому итоговая ссылка на флейк — это
`github:<ВАШ_ЮЗЕР>/<ВАШ_РЕПО>#nixos`
(имя после `#` — это ключ в `nixosConfigurations`, а не произвольное
"имя хоста"; если хотите другое имя — переименуйте атрибут в `flake.nix`
и заодно `networking.hostName` в `configuration.nix`, чтобы не разъезжались).

## Важно перед началом

- Flakes видят только файлы, добавленные в git (`git add`), даже для
  локальной директории. Ветку с изменениями нужно **запушить на GitHub**,
  прежде чем ссылаться на неё как на `github:...` — свежие незакоммиченные
  правки удалённая сборка не увидит.
- `hardware-configuration.nix` в репозитории **нет** — он генерируется на
  целевой машине и коммитится туда одним из шагов ниже. До этого момента
  `configuration.nix` импортирует его условно (`builtins.pathExists`), так
  что флейк спокойно вычисляется и без него — это нужно, чтобы disko вообще
  мог прочитать `disko.devices` из этого же флейка на шаге партиционирования.
- В установочном ISO флейки обычно не включены по умолчанию — добавляйте
  `--extra-experimental-features "nix-command flakes"` к командам ниже, либо
  один раз выполните `export NIX_CONFIG="experimental-features = nix-command flakes"`.
- Т.к. в `flake.nix` есть `nixConfig` (кэш niri.cachix.org), при первом
  использовании флейка `nix` спросит подтверждение доверия этим настройкам —
  либо подтвердите интерактивно, либо добавляйте `--accept-flake-config`.

## Установка с нуля

1. Загрузиться с установочного ISO NixOS на целевой машине, поднять сеть
   (`nmtui` / `nmcli` — `networking.networkmanager.enable = true` уже есть
   в `configuration.nix`, но на самом ISO сеть настраивается отдельно).

2. Отредактировать `disko.nix` под реальное имя диска на этой машине
   (`lsblk`, проверить `/dev/disk/by-id/...` или `/dev/nvme0n1` — как у вас
   сейчас в файле), закоммитить и запушить в свой репозиторий на GitHub.

3. Разметить и смонтировать диски через disko, читая описание прямо из
   вашего флейка на GitHub (клонировать репозиторий локально не обязательно):

   ```bash
   sudo nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko -- --mode disko --flake "github:taharakuro/NixOS#nixos"
   ```

4. Сгенерировать `hardware-configuration.nix` **с флагом `--no-filesystems`**
   (без него nixos-generate-config пропишет свои `fileSystems`, которые
   конфликтуют с теми, что уже генерирует disko — именно это чинили в
   прошлый раз):

   ```bash
   sudo nixos-generate-config --no-filesystems --root /mnt --dir /tmp/repo
   ```

   Проще всего склонировать репозиторий в `/tmp/repo` заранее (`git clone`),
   сгенерировать файл прямо туда поверх остальных, затем:

   ```bash
   cd /tmp/repo
   git add hardware-configuration.nix
   git commit -m "add hardware-configuration.nix"
   git push
   ```

5. Теперь, когда файл есть в удалённом репозитории, ставить систему уже
   напрямую с GitHub:

   ```bash
   sudo nixos-install --flake "github:taharakuro/NixOS#nixos"
   ```

   `nixos-install` задаст пароль root в конце — на этом установка закончена.

6. После перезагрузки в новую систему дальнейшие обновления — уже обычным
   `nixos-rebuild switch --flake "github:<ВАШ_ЮЗЕР>/<ВАШ_РЕПО>#nixos"` либо
   локально из клона репозитория.

## Что если нужно ставить с локальной правкой, ещё не запушенной

Шаги 3 и 5 точно так же работают с локальным путём вместо `github:...`,
например `--flake "/tmp/repo#nixos"` — это удобно, чтобы проверить перед
пушем, что всё собирается.
