<?php
require '/var/www/winconnect/vendor/autoload.php';
$app = require_once '/var/www/winconnect/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();
$result = DB::connection('oracle')->select("SELECT column_name FROM all_tab_columns WHERE table_name = 'PCPRODUT' AND column_name LIKE '%CODAUXILIAR%'");
print_r($result);
