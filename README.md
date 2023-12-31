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
     -f, --force         Genera el PDF, aunque deba sobrescribir el destino.
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

    Ejemplos:

     1. Convierte una imagen en un PDF llamado imagen.pdf con tamaño A4:

        $ img2pdf.sh imagen.jpg

     2. Ídem, pero cambia el nombre del PDF resultante:

        $ img2pdf.sh -odocumento.pdf imagen.jpg

     3. Hace la conversión pero el tamaño es A3:

        $ img2pdf.sh -a3 imagen.jpg

     4. Convierte varias imágenes obteniéndose un único PDF. La primera imagen
        ocupará la primera página y la segunda, la segunda:

        $ img2pdf.sg -odocumento.pdf imagen1.jpg imagen2.jpg

