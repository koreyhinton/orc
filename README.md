# orc

code generation for imperative flow/orchestration

## code templates

imperative snippets:

    ./lib/src/templates/{lang}/com/koreyhinton/{lib}/snippets/{snippet}.sh

library types, printed as one whole file:

    ./lib/src/templates/{lang}/com/koreyhinton/{lib}/models.sh <version>

library version, checked by models.sh and snippets/import.sh:

    ./lib/src/templates/{lang}/com/koreyhinton/{lib}/version.sh

(older libraries print their types from one `classes/{Class}.sh` per type)

## variable namespace mapping tools

    ./lib/src/main/bash/com/koreyhinton/nsmap/nsmap

    ./lib/src/main/bash/com/koreyhinton/nsmap/nsremap

## documentation

[s3 model](docs/models/s3.svg)
