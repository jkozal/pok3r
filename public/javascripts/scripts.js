function mouseOver(link){
	document.getElementById(link).className = "trans_box3"
}

function mouseOut(link){
	document.getElementById(link).className = "trans_box2"
}

function rozwin(co){
	if(document.getElementById(co).style.display == \'block\') {document.getElementById(co).style.display=\'none\';}
	else {document.getElementById(co).style.display=\'block\';}
}

function orderTotal(oform, prefix)
{
var stawka = oform[prefix + "_stawka"];
var hold = oform[prefix + "_hold"];
var kurs = oform[prefix + "_kurs"];
var result = oform[prefix + "_result"];

if (stawka == "")return;
if(isNaN(stawka.value) || (stawka.value <= 0))
{
   stawka.value = "";
   hold.value = "";
}
else hold.value = (Math.round(stawka.value * kurs.value * 100))/100;

visTotal(oform, prefix);
}

function visTotal(oform, prefix)
{
var hold = oform[prefix + "_hold"];
var result = oform[prefix + "_result"];

if (result.value != hold.value)
   result.value = hold.value;
}

function form_zatwierdz()
{
if(isNaN(document.getElementById(\'stawka\').value) || document.getElementById(\'stawka\').value < 10 || document.getElementById(\'stawka\').value > '.round(mysql_result($user_query,0,"bilans") /10).') {
	alert(\'Stawka musi byæ mniejsza od '.round(mysql_result($user_query,0,"bilans")/10).', oraz wiêksza od 10!\');
}
else {
	if('.round($total).' > 50) {alert(\'Maksymalny ³¹czny kurs na kupon to 50.00\');}
	else {document.getElementById(\'kupon_zatwierdz\').submit();}
}
}