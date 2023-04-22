{fetchurl}: {
  name,
  date,
  sha256,
  continent,
  country ? null,
}:
if (country != null)
then
  fetchurl {
    inherit sha256;
    url = "https://download.geofabrik.de/${continent}/${country}/${name}-${date}.osm.pbf";
  }
else
  fetchurl {
    inherit sha256;
    url = "https://download.geofabrik.de/${continent}/${name}-${date}.osm.pbf";
  }
