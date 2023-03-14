{ lib
, fetchFromSourcehut
, buildGoModule
, buildPythonPackage
, srht
, redis
, alembic
, pystache
, pytest
, factory_boy
, python
, unzip
}:

buildPythonPackage rec {
  pname = "todosrht";
  version = "0.74.4";

  src = fetchFromSourcehut {
    owner = "~sircmpwn";
    repo = "todo.sr.ht";
    rev = version;
    sha256 = "sha256-iMussn/GBF4R930TTWGem73DSgIJEIg0BIF5cBXUJwk=";
  };

  postPatch = ''
    substituteInPlace Makefile \
      --replace "all: api" ""
  '';

  todosrht-api = buildGoModule ({
    inherit src version;
    pname = "todosrht-api";
    modRoot = "api";
    vendorSha256 = "sha256-LB1H4jwnvoEyaaYJ09NI/M6IkgZwRet/fkso6b9EPV0=";
  } // import ./fix-gqlgen-trimpath.nix { inherit unzip; });

  propagatedBuildInputs = [
    srht
    redis
    alembic
    pystache
  ];

  preBuild = ''
    export PKGVER=${version}
    export SRHT_PATH=${srht}/${python.sitePackages}/srht
  '';

  postInstall = ''
    ln -s ${todosrht-api}/bin/api $out/bin/todosrht-api
  '';

  # pytest tests fail
  nativeCheckInputs = [
    pytest
    factory_boy
  ];

  dontUseSetuptoolsCheck = true;
  pythonImportsCheck = [ "todosrht" ];

  meta = with lib; {
    homepage = "https://todo.sr.ht/~sircmpwn/todo.sr.ht";
    description = "Ticket tracking service for the sr.ht network";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ eadwu ];
  };
}
