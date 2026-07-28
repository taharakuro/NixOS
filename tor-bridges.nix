# ВАЖНО: этот файл не должен попасть в git. Добавьте в .gitignore одну из
# строк:
#   secrets/tor-bridges.nix
# или, если планируете класть сюда что-то ещё личное:
#   secrets/
#
# Персональные obfs4-мосты не предназначены для публичного
# распространения — если репозиторий (или его форк/бэкап) окажется
# публичным, мосты могут заблокировать раньше времени, а сама их
# уникальная комбинация — лишний идентифицирующий след.
{
  services.tor.settings.Bridge = [
    "obfs4 195.52.145.38:1677 3234D58257F100D6B5D8AB6F43176E6946EFD513 cert=QEI46C0ldwctxz+QT+sUpvyDYSe3EhhmQOA6T4Qt3kZBzHQA7nx5ihiusL+sFASJUEEYXw iat-mode=0"
    "obfs4 166.88.2.83:17443 7F65C4721C582D3D2CD86B678A72D88E98C1950E cert=cT0YJE4StbOtuRKVyG3gznJlDwIlj57MBbQViEt7aKRRG6gqbaycWpCz4h3+knVFhXtbaw iat-mode=0"
    "obfs4 51.68.81.140:2098 F205CB5B969389061477609F8E03470B982F64C1 cert=6hFyrclX8Cg16jHGbtYqZxbGxj+p0flBn2EYZu+hvx/tGL4GROXSvBtwVQ1sRYFbi0++fQ iat-mode=0"
    "obfs4 57.128.45.196:18384 E30D5552BEE79C5E8C61A943E9B3D2949F227C41 cert=boaTbcdp+rFHgUvweiAg60UUUpLZWecGl0uXRU358L/a7ZMrAnS/BodUKM3eyfWC+UVXTg iat-mode=0"
  ];
}
