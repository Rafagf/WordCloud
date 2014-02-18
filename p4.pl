#!"C:\strawberry\perl\bin\perl.exe"

use 5.010;
use warnings;
use utf8; # Script en utf8
use CGI qw(param);
use LWP::Simple;	#Get para la semilla
use XML::LibXML;	#Liberia parser XML


print "Content-Type:text/html; charset=utf-8\n\n"; #para el unicode en html
print "<html><head><title>Practica 4</title></head><body>";
open FORMAS, "<:utf8", "10000_formas_CREA.TXT";

if (param()) {
	#print "Contenido del campo es: ";
	$entrada = param('buscar'); 
	#Guardamos el valor de entrada con vistas a usar el buscador
	$entrada2 = $entrada;
	#print $entrada;
	$buscador = 0;
	
}

if (param()==2){

	$entrada = param('buscar');
	$entrada2 = $entrada;
	$tag = param('tag');
	$buscador = 1;
	
}

binmode STDOUT, ":utf8";

#Opcion 1 para el formulario HTM (Construyendo la URL)
$feedParte1 = "http://ep00.epimg.net/rss/";
$feedParte2 = $entrada;
$feedParte3 = "/portada.xml";
$entrada = $feedParte1.$feedParte2.$feedParte3;

#Opcion 2 (Pasandole directamente la URL del feed ($entrada). Comentar la opcion 1	

#Descarga y apertura del feed actualizado 
$content = get($entrada); 
#$content = get("http://ep00.epimg.net/rss/internacional/portada.xml");
die "Couldn't get it!" unless defined $content; 

$texto = "";
$html = "";

#Creamos la instancia del analizador
my $parser = XML::LibXML->new();
#my $documento = $parser -> parse_file("contenido.xml");
my $documento = $parser -> parse_string($content);

if($buscador==0){
	#Cogemos del texto todo lo que esta dentro de la etiqueta category
	foreach my $entrada ($documento->findnodes('//category')) {

	  	#Nos quedamos con lo que contiene el CDATA
		$texto = $texto.$entrada->textContent;
		$texto = $texto." ";
	}

	#Cogemos del texto todo lo que esta dentro de Content:encoded (HTML)
	foreach my $entrada ($documento->findnodes('//content:encoded')) {

	  	#Nos quedamos con lo que contiene el CDATA
		$html = $html.$entrada->textContent;
		$html = $html." ";
	}


	#Sustituimos & por &amp en el codigo HTML para evitar errores
	$html =~ s/&/&amp\;/g;

	$textoImportante = "";
	$textoNormal = "";

	#Parseamos el codigo HTML
	$documento = $parser->parse_html_string($html);

	#Cogemos lo rodeado por etiquetas <p>
	foreach my $entrada ($documento->findnodes('//p')) {
		$textoNormal = $textoNormal.$entrada->textContent." ";
	}

	#Etiquetas <a>. Palabras a destacar
	foreach my $entrada ($documento->findnodes('//a')) {

		$textoImportante = $textoImportante.$entrada->textContent." ";
	}

	#Etiquetas <strong>. Palabras a destacar
	foreach my $entrada ($documento->findnodes('//strong')) {

		$textoImportante = $textoImportante.$entrada->textContent." ";
	}

	#Etiquetas <em>. Palabras a destacar
	foreach my $entrada ($documento->findnodes('//em')) {

		$textoImportante = $textoImportante.$entrada->textContent." ";
	}

	#Concatenamos textos
	$texto = $texto.$textoNormal;

	#Concatenamos con texto a destacar por un determinado factor
	$factor = 3;

	while($factor > 0){
	
		$texto = $texto.$textoImportante;
		$factor = $factor - 1;

	}

	$May = '[A-ZÁÉÍÓÚÑ]';
	$Min = '[a-záéíóúñ]';
	$Empieza_May = "(?:$May$Min+)";
	$NP = "(?:$Empieza_May $Empieza_May+)";
	$NPDE = "(?:$Empieza_May (de|l) $Empieza_May+)";
	@NPS = $texto =~ /($NP)/g;
	@NPS2 = $texto =~ /($NPDE)/g;	

	#Palabras compuestas (2 palabras seguidas mayúsculas)
	foreach (@NPS){

		#La introduzco 2 veces para darle mas peso
		push @palabras, $_;
		push @palabras, $_;

	}

	#Palabras compuestas (con de o del por medio)
	foreach (@NPS2){

		#La introduzco 2 veces para darle mas peso
		push @palabras, $_;
		push @palabras, $_;

	}

	#Separamos por cualquier cosa que no sean letras
	@palabrasAux = split(/[^a-zA-ZáéíóíÁÉÍÓÚñÑ]/, $texto);

	$totalPalabras = 0;	
	foreach (@palabrasAux){

		$totalPalabras = $totalPalabras+1;
		#Pasamos todas las palabras a mayusculas
		$_ = lc($_);
		push @palabras, $_;
	}

	my %mihash;
	$contador = 0;

	#Contamos las ocurrencias de cada una de las palabras
	foreach (@palabras){

		$contador = 0;
		$aux = $_;
		foreach (@palabras){
		
			if ($aux eq $_){	
				$contador += 1;
			}
		}
		#print $aux , " ", (1000000/$totalPalabras)*$contador, "\n";
		$mihash{$aux} = (1000000/$totalPalabras)*$contador;
	}

	#Creamos una hash con las palabras del 10000_formas
	my %hashformas;
	$cont_aux = 0;
	while (<FORMAS>){
		
		#Las 2 primeras lineas no tienen informacion interesante
		chop;
		if($cont_aux > 1){
			@columnas = split(' ', $_);
			$hashformas{$columnas[1]}=$columnas[3];
		}
		else{
			$cont_aux = $cont_aux + 1;
		}
	}

	#Construimos hash definitivo comprobando que palabras salen en hashforms y realizando frec noticia / frec formas
	my %hashdefinitivo;
	foreach my $key (keys %mihash) { # keys devuelve las llaves

		if (defined $hashformas{$key}){
			
			$hashdefinitivo{$key} = $mihash{$key}/$hashformas{$key};
		}
	}

	#Para ver el contenido de hashdefinitivo
	foreach my $key (keys %hashdefinitivo) { # keys devuelve las llaves
	#	print $key, " ", $hashdefinitivo{$key}, "\n";
	}
	
	#Creacion pagina web
	#open (INDEX, '> index.html');	

	print "<html> <head> \n <title> Práctica 4. Buscador </title> \n </head> \n <body>";
	#Sacamos por pantallas las 100 con mejor coeficiente
	
	#print sort(values(%hashdefinitivo));
	
	$contador = 0;
	

	print '<form action="p4.pl?buscar=$entrada2&tag=""" method="get">';
	print "		Feed a utilizar: 	<input type=\"text\" name=\"buscar\" size=\"70\" value=\"$entrada2\"><br>";
	print 'Introduzca palabras a buscar: <input type="text" name="tag" />';
	print '<input type="submit" value="Enviar" />';
	print '		</form>';

	foreach my $palabra( sort ordenar_por_valor keys %hashdefinitivo) {
	    if($contador < 100){			
			my $valor= $hashdefinitivo{$palabra};
			$contador = $contador + 1;
			$fuente = $valor *2; #Le añado el factor 2 para obtener un resultado mas vistoso
			$fuente = $fuente . "pt";
			#print INDEX "<span title=\"frecuencia\" style=\"font-size: $fuente \"> $palabra </span>";
			print "<a href=\"p4.pl?buscar=$entrada2&tag=$palabra\" style=\"font-size: $fuente \"> $palabra </a>\n";

		}
	}	
	
	sub ordenar_por_valor {
	return $hashdefinitivo{$a} <= $hashdefinitivo{$b};
}
}

#open MISALIDA, ">:utf8", "misalida.txt";

if($buscador==1){

	print "<html> <head> \n <title> Práctica 4. Buscador </title> \n </head> \n <body>";
	print "<p><h2><b>Tags elegidos: $tag</b></h2></p>";
	#Obtenemos las palabras de la consulta
	@palabrasConsulta = split ' ', $tag;

	$contadorLinks = 0;
	
	foreach (@palabrasConsulta){
				
		@noticias = $documento -> findnodes('//item');
		$numNoticias = $#noticias + 1;
		#print "<p>Numero de noticias: $numNoticias</p>";
		$palabra = $_;
		$apariciones_totales = 0;		
		$contadorLinksPalabra = 0;

		foreach $item (@noticias){
			$contentEncodeNode = $item->findnodes('./content:encoded');
			$htmlContent = $contentEncodeNode->to_literal();
			$frecuencia = frecuencia($htmlContent, $palabra);

			#$contadorLinks es el contador que lleva la cuenta de TODOS los links encontrados
			#$contadorLinksPalabra es el contador que lleva la cuenta de los links encontrados para la palabra actual
			#$frecuencia es TF a la hora de calcular TF-IDF
			#TF = frecuencia de aparicion de un termino en un documento
			if($frecuencia > 0){
			
				$link = $item->findnodes('./link');
				$links[$contadorLinks] = $link;
				$frecuenciaLink[$contadorLinks] = $frecuencia;
				$titleLink[$contadorLinks] = $item->findnodes('./title');
				$descriptionLink[$contadorLinks] = $item->findnodes('./description');
				$contadorLinks = $contadorLinks + 1;
				$contadorLinksPalabra = $contadorLinksPalabra + 1;
			
			}
		}
		
		#Calculamos ahora IDF de la palabra que estamos buscando
		#IDF = log (N/ni)	
		if($contadorLinksPalabra > 0){
			$idf_aux = log($numNoticias/$contadorLinksPalabra);
			
			#Lo repetimos usando un bucle para facilitar los calculos del tfidf mas adelante
			for(my $i=$contadorLinks-$contadorLinksPalabra; $i<=$contadorLinks; $i++){
				$idf[$i] = $idf_aux;
			}
		}
	
	}
		
	#Ahora calculamos el tf-idf para cada uno de los links
	$contadorAux = 0;
	foreach (@links){
	
		$tfidf[$contadorAux] = $frecuenciaLink[$contadorAux]*$idf[$contadorAux];
		$contadorAux = $contadorAux + 1;
	}
	
	#Antes de mostrar los links los ordenamos por su TF-IDF
	ordenarLinks(\@tfidf, \@frecuenciaLink, \@links, \@idf, \@titleLink, \@descriptionLink);
	
	#print "<p>$apariciones_totales apariciones totales  repartidas en $contadorLinks links</p>";
	$contadorAux = 0;
	foreach (@links){
		 		
		print "<p><h1><b>$titleLink[$contadorAux]</b></h1></p>";
		print "<p><a href=$l> $_ </a></p>";
		print "<p><h3>$descriptinLink[$contadorAux]</h3></p>";
		#print "<p>IDF: $idf[$contadorAux]</p>";
		#print "<p>TF: $frecuenciaLink[$contadorAux] </p>";
		print "<p><h4>Apariciones: $frecuenciaLink[$contadorAux]</h4></p>";
		print "<p>TF-IDF es: $tfidf[$contadorAux]</p>";
		$contadorAux = $contadorAux + 1;
		
	}
	
	#Para conseguir la frecuencia de una palabra en un texto
	sub frecuencia{
		my $texto = shift;
		my $palabra = shift;
		my $frecuencia = 0;
				
		my @palabras = split ' ', $texto;
		foreach (@palabras){
			if($_ =~ m/$palabra/i){
				$frecuencia = $frecuencia+1;
			}
		}
		return $frecuencia;
	}
	
	#Para ordenar los links mediante su TF-IDF
	sub ordenarLinks{

		my $lista1 = shift; #tfidf
		my $lista2 = shift;	#tf
		my $lista3 = shift;	#links
		my $lista4 = shift;	#idf
		my $lista5 = shift; #titleLink
		my $lista6 = shift; #descriptionLink
		
		my @lista_aux = @$lista1;
		my $n = $#lista_aux;
		for(my $i=0; $i<=$n; $i++){
			for(my $j=$n; $j>$i; $j--){
				if($lista1->[$j]>$lista1->[$j-1]){
					my $aux = $lista1->[$j-1];
					$lista1->[$j-1] = $lista1->[$j];
					$lista1->[$j] = $aux;
					
					$aux = $lista2->[$j-1];
					$lista2->[$j-1] = $lista2->[$j];
					$lista2->[$j] = $aux;
					
					$aux = $lista3->[$j-1];
					$lista3->[$j-1] = $lista3->[$j];
					$lista3->[$j] = $aux;
					
					$aux = $lista4->[$j-1];
					$lista4->[$j-1] = $lista4->[$j];
					$lista4->[$j] = $aux;
					
					$aux = $lista5->[$j-1];
					$lista5->[$j-1] = $lista5->[$j];
					$lista5->[$j] = $aux;
										
					$aux = $lista6->[$j-1];
					$lista6->[$j-1] = $lista6->[$j];
					$lista6->[$j] = $aux;
					
				}
			}
		}
	}
}