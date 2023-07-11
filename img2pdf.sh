#!/bin/sh
# Convierte una imagen en un pdf.


help() {
   echo "$(basename $0) [-opciones] imagen1 [imagen2 ...]
   Transforma archivos de imagen en PDFs con dimensiones estándar DIN-A,
   de modo que las imagenes se rescalan para ocupar hojas completas.
   El script necesita ImageMagick para realizar la conversión.

Opciones:

 -a, --din-a [0-5]   Tamaño del PDF resultante (de A0 a A5). Por
                     defecto, 4.
 -b. --border N      Anchura en pixeles del borde que se añade a la
                     imagen original. Por defecto, 20.
 -f, --force         Genera el PDF, aunque deba escribir otro con
                     su mismo nombre.
 -h, --help          Muestra esta misma ayuda.
 -o, --output [XXX]  Nombre del PDF resultante. Si se proporcionan
                     varias imágenes de entrada, se presupone -s.
                     '-' envía el PDF a la salida estándar.
 -q, --quiet         No muestra los mensajes de información.
 -s, --single        Junta en un único PDF todas las imágenes.
                     Esta función requiere Ghostscript.
 -v, --vertical      Siempre obtiene un PDF vertical, por lo que
                     el programa rota 90º la imagen si detecta
                     que ésta es más ancha que alta.
"
}


error() {
   local ERRCODE=$1
   shift 

   echo "$@" >&2

   # El código de error 0, es sólo para mostrar
   # un mensaje de advertencia sin abortar el programa.
   [ "$ERRCODE" -eq 0 ] && return 0
   exit "$ERRCODE"
}


#
## Muestra el mensaje directamente en la terminal
#
log() {
   [ -n "$quiet" ] && return 0
   echo -n "$@" > /dev/tty
}


es_entero() {
   expr "$1" : "[0-9]\+$" > /dev/null
}


#
# Extrae las dimensiones de la imagen en formato:
# WIDTH HEIGHT
#
extrae_tam() {
   $CONVERT "$1" -print '%w %h' /dev/null
}


#
# Obtiene el lado mayor del DIN-A
# $1: El formato (a0, a1, etc)
#
calc_formato() {
   local num=${1#a}
   $PYTHON -c 'L=2**.25*100
for i in range(0,'"$num"'): L=L/2**.5
print(L)'
}


#
# Obtiene el tamaño final que tendrá la imagen (ya con bordes)
# $1: La imagen.
# $2: El ancho del borde a añadir.
#
# La relación entre los lados debería ser raíz de 2 para ajustarse
# a las dimensiones del PDF, pero es probable que no sea así.
#
calc_tam() {
   local width height max min cmax cmin image=$1 border=$2 
   read width height <<EOF
$(extrae_tam "$image") 
EOF
   height=$((height+border))
   width=$((width+border))
   es_mayor "$width" "$height"
   comp=$?
   if [ $comp -eq 0 ]; then
      max=$width
      min=$height
   else
      max=$height
      min=$width
   fi

   # Corregimos dimensiones para que su relación sea raíz de 2.
   cmin=$($PYTHON -c 'print(round('"$max"'/2**.5))')
   if es_mayor "$cmin" "$min"; then
      min=$cmin
   else
      max=$($PYTHON -c 'print(round('"$min"'*/2**.5))')
   fi

   if [ $comp -eq 0 ]; then
      width=$max
      height=$min
      rotate=$rotate
   else
      height=$max
      width=$min
      rotate=
   fi
   echo "${width}x$height $max $rotate"
}


#
# Comprueba si un número es mayor que otro
#
es_mayor() {
   echo "$1 $2" | awk '{exit !($1 > $2)}'
}


PYTHON=$(command -v python || command -v python3)
[ -n "$PYTHON" ] || error 3 "Se necesita Python en el sistema para hacer operaciones aritméticas."
CONVERT=$(command -v convert)
[ -n "$CONVERT" ] || error 3 "No se encuentra 'convert'. Es probable que necesite instalar ImageMagick."
GHOSTVIEW=$(command -v gs)


{ # Tratamiento de los argumento del programa.
   requiere_parametro() {
      local opts="a:b:vhfso:q"

      expr "$opts" : ".*$1:" > /dev/null
   }

   format=4
   border=20
   retr=0
   while [ $# -gt $retr ]; do
      case $1 in
         -a|--din-a)
            format=$2
            if ! es_entero "$format" || [ "$format" -lt 0 ] || [ "$format" -gt 5 ]; then
               error 1 "DIN-A$format no soportado. Debe ser entre a0 y a5"
            fi
            shift
            ;;
         -b|--border)
            border=$2
            es_entero "$border" || error 1 "$1 requiere un número positivo"
            shift;;
         -v|--vertical)
            rotate=1
            ;;
         -f|--force)
            force=1
            ;;
         -h|--help)
            help
            exit 0;;
         -q|--quiet)
            quiet=1
            ;;
         -s|--single)
            single=1
            ;;
         -o|--output)
            target="$2"
            shift;;
         --)
            shift
            break ;;
         --??*=*)  # --opt=value
            arg=${1%%=*}
            value=${1#*=}
            shift
            set -- "$arg" "$value" "$@"
            continue
            ;;
         --*|-?)
            error 2 "$1: Opción desconocida"
            ;; 
         -??*)  # Opciones cortas fusionadas.
            arg=$(printf "%.2s" "$1")
            arg=${arg#?}
            rarg="${1#-$arg}" 
            requiere_parametro "$arg" || rarg="-$rarg"
            shift
            set -- -"$arg" "$rarg" "$@"
            continue
            ;;
         *) arg=$1
            shift
            set -- "$@" "$arg"
            retr=$((retr+1))
            continue;;
      esac
      shift
   done

   case $# in
      0) error 2 "¿Qué imagen quiere convertir?";;
      1) if [ -n "$single" ]; then
            error 0 "'-s' es redundante: sólo se convertirá una imagen."
            single=
         fi
         ;;
      *) [ -n "$target" ] && single=1;;
   esac
}

[ -n "$single" ] && [ -z "$GHOSTVIEW" ] && error 3 "Ghostscript no encontrado. Se necesita para crear un PDF único."

target=${target:-${1%.*}.pdf}
if [ -z "$force" ]; then
   [ "$target" != "-" ] && [ -f "$target" ] && error 4 "'$target' existe: bórrelo o utilice la opción -f."
   if [ -z "$single" ]; then
      for image in "$@"; do
         [  -f "${image%.*}.pdf" ] && error  4 "'${image%.*}.pdf' existe: bórrelo o utilice la opción -f."
      done
   fi
fi

format=$(calc_formato "$format")
copy=$(mktemp -p /tmp "tmpimg.XXXXX")

for image in "$@"; do
   shift
   [ -f "$image" ] || { error 0 "'$image': archivo no encontrado. Se salta."; continue; } 
   # Recortamos para dejar sólo la superficie dibujada y eliminar bordes vacíos.
   $CONVERT -trim "$image" "$copy"
   read dim max rotate<<EOF
$(calc_tam "$copy" "$border")
EOF
   #density=$(dc -e "6k $max $format/p")
   density=$($PYTHON -c "print($max/$format)")
   rotate=${rotate:+"-rotate 90"}
   if [ -z "$single" ]; then
      output="$target"
   else
      output=$(mktemp -p /tmp "tmppdf.XXXXX.pdf")
      # Va acomulando los PDF individualees en $@,
      # mientras elimina los nombres de las imágenes.
      set -- "$@" "$output"
   fi
   # Centra la imagen y genera el PDF
   log "Generando el pdf de '$image'... "
   $CONVERT "$copy" -gravity center -background white -extent "$dim" $rotate -units PixelsPerCentimeter -density $density PDF:"$output"
   log "$output.\n"
done

if [ -n "$single" ]; then
   # Aunque se proporcionaron varias imágenes, sólo una existía.
   if [ $# -eq 1 ]; then
      mv "$1" "$target"
      shift
   else
      log "Fundiendo los PDFs individuales... "
      "$GHOSTVIEW" -q -dNOPAUSE -sDEVICE=pdfwrite -sOUTPUTFILE="$target" -dBATCH "$@"
      log "$target.\n"
   fi
fi

rm -f "$copy" "$@"

