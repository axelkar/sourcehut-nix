{ lib
, fetchFromSourcehut
, buildPythonPackage
, srht
, pygit2
, python
}:

buildPythonPackage rec {
  pname = "mansrht";
  version = "0.16.0";

  src = fetchFromSourcehut {
    owner = "~sircmpwn";
    repo = "man.sr.ht";
    rev = version;
    sha256 = "sha256-QxM9WwqvWyqHfck+P+CMoQ2p+8ZdbO8KOJ9qa40nsWI=";
  };

  propagatedBuildInputs = [
    srht
    pygit2
  ];

  preBuild = ''
    export PKGVER=${version}
    export SRHT_PATH=${srht}/${python.sitePackages}/srht
  '';

  pythonImportsCheck = [ "mansrht" ];

  meta = with lib; {
    homepage = "https://git.sr.ht/~sircmpwn/man.sr.ht";
    description = "Wiki service for the sr.ht network";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ eadwu ];
  };
}
