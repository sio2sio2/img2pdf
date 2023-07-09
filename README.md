# img2pdf

    img2pdf.sh [-opciones] imagen1 [imagen2 ...]
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
