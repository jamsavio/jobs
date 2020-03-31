<?php
$ativar = '';
$desativar = '';

$filename = "C:\Users\Jam\AppData\Roaming\FBS Trader 4\MQL4\Files\control_ea.txt";
$handle = fopen($filename, "r");
$contents = fread($handle, filesize($filename));
fclose($handle);

if(!isset($_GET['ativar']) && !isset($_GET['desativar'])){
	if($contents == "turnon") $ativar = "on";
	else if($contents == "turnoff") $desativar = "on";
}

else if(isset($_GET['ativar'])){
	$ativar = $_GET['ativar'];
	$desativar = '';
}

else if(isset($_GET['desativar'])){
	$desativar = $_GET['desativar'];
	$ativar = '';
}

if($desativar=="on" && isset($_GET['desativar'])){
	$myfile = fopen($filename, "w") or die("Unable to open file!");
	$txt = "turnoff";
	fwrite($myfile, $txt);
	fclose($myfile);
	echo "<center><b style='color: green'>Comando <span style='color: red'>[desligar]</span> enviado com sucesso!</b></center>\n";
	header("Refresh:1; url=teste.php");
}

else if($ativar=="on" && isset($_GET['ativar'])){
	$myfile = fopen($filename, "w") or die("Unable to open file!");
	$txt = "turnon";
	fwrite($myfile, $txt);
	fclose($myfile);
	echo "<center><b style='color: green'>Comando <span style='color: blue'>[ligar]</span> enviado com sucesso!\n</b></center>";
	header("Refresh:1; url=teste.php");
}

?>

<!DOCTYPE HTML>
<html>
<head>
<title>BF Grid Master EA</title>
<!-- Bootstrap CSS -->
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css">
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js"></script>
</head>

<body>
	<center><br><br><br><br>BF Grid Master EA<br><br>
	<form action="teste.php" method="GET">
		<div class="btn-group btn-group-toggle" data-toggle="buttons">
  			<label class="btn btn-secondary <?php if($ativar=='' && $desativar == '' || $ativar=="on") echo "active"; ?>">
    				<input type="radio" name="ativar" id="on" name="on" autocomplete="off"> On
  			</label>
 			<label class="btn btn-secondary <?php if($desativar=="on") echo "active"; ?>">
    				<input type="radio" name="desativar" id="off" autocomplete="off"> Off
  			</label>
		</div>
		<button type="submit" >
          		<span class="glyphicon glyphicon-refresh"></span> Refresh
        	</button>
	</form>
	</center>
</body>

</html>