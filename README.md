# OU Template Conversion

Download the compiled binary from the latest successful [pipeline artifacts](https://git.uark.edu/omniupdate/ou-template-converters/pipelines?scope=branches&page=1).

Run `ou-convert -help` for full usage information.

```sh
ou-convert 
    --tmpl "https://its.uark.edu/_resources/ou/templates/itspage.tmpl" 
    --map maps/techarticle.map ta/*.pcf
```