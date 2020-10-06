<?php
header('Content-Type: application/json;');

$response = array(
    "error" => false,
    "message" => "",
    "datas" => array(),
    "callback" => ""
);

try {
    if (count($_POST) > 0) {
        if (isset($_POST["password"]) && isset($_POST["function"])) {
            if ($_POST["password"] != "password_api") throw new Error("Access denied");

            switch ($_POST["function"]) {
                case 'connect':
                    $response["datas"] = connect();
                    break;
                case 'set_unit_state':
                    $response["message"] = set_unit_state();
                    break;
                case 'upload':
                    $response["message"] = upload();
                    break;
                case 'update':
                    $response["datas"] = update();
                    break;
                default:
                    throw new \Error("Not allowed function");
                    break;
            }

            $response["callback"] = $_POST["function"];
        } else {
            throw new Error("Access denied");
        }
    }
} catch (\Throwable $th) {
    $response["error"] = true;
    $response["message"] = $th->getMessage();
} finally {
    echo json_encode($response, JSON_FORCE_OBJECT);
}

function upload(): string
{
    try {
        if (isset($_FILES['capture']) && isset($_POST["path"])) {
            $file_name = $_FILES['capture']['name'];
            $file_size = $_FILES['capture']['size'];
            $file_tmp = $_FILES['capture']['tmp_name'];
            //$file_type = $_FILES['capture']['type'];
            $file_ext = strtolower(end(explode('.', $_FILES['capture']['name'])));
            $extensions = array("jpeg", "jpg", "png");
            if (in_array($file_ext, $extensions) === false) {
                throw new \Error("extension not allowed, please choose a JPEG or PNG file.");
            } else {
                if ($file_size > 2097152) {
                    throw new \Error('File size must be excately 2 MB');
                } else {
                    //Création du répertoire propre à l'instance 
                    $path = "public/upload/" . str_replace('"', "", str_replace("&quot;", "", $_POST["path"]));
                    if (file_exists($path) == false) {
                        mkdir($path, 0777);
                    }

                    move_uploaded_file($file_tmp, $path . "/" . $file_name);
                    return "Upload terminé";
                }
            }
        } else {
            throw new \Error("no file submited");
        }
    } catch (\Throwable $th) {
        throw $th;
    }
}

function set_unit_state(): string
{
    try {
        $uid =  str_replace('"', "", str_replace("&quot;", "", $_POST["uid"]));

        $path_file = "units.xml";

        if (file_exists($path_file) == false) {
            throw new Error("File does not exist : " . $path_file);
        }

        $lock = "lock.lock";
        if (file_exists($lock)) {
            //wait
        } else {
            $handle = fopen($lock, 'w');

            try {
                $xml = new DOMDocument();
                $xml->load($path_file);
                $xpath = new DOMXPath($xml);

                $el_units = $xpath->query('//root/units');

                //if ($el_units != null && count($el_units) > 0) {
                $units = $el_units->item(0);

                if ($units != null) {
                    $el = $xpath->query('//root/units/unit[@uid="' . $uid . '"]');
                    if ($el->item(0) != null) {
                        $units->removeChild($el->item(0));
                    }

                    $str_xml = str_replace("&quot;", "", urldecode(base64_decode($_POST["unit"])));
                    if (empty($str_xml) == false) {
                        $frag = $xml->createDocumentFragment();
                        $frag->appendXML($str_xml);
                        $units->appendChild($frag);
                        $xml->save($path_file);
                    }
                }
                // }
            } catch (\Throwable $eth) {
                throw $eth;
            } finally {
                fclose($handle);
                unlink($lock);
            }


            return "Synchronisation terminée";
        }

        return "Attente d'accès au fichier";
    } catch (\Throwable $th) {
        throw $th;
    }
}


function update(): array
{
    try {
        $version = 2;

        $path = "public/download";
        if (file_exists($path) == false) {
            mkdir($path, 0777);
            $version = 0;
        }

        $hash_md5 = "";
        $pbo_path =  "public/download/morrigan.pbo";
        if (file_exists($pbo_path) == false) {
            $version = 0;
        }
        else{
            $hash_md5 = md5_file($pbo_path);
        }
        
        $url = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http") . "://" . $_SERVER["HTTP_HOST"] . "/HUD/";

        return array(
            "version" => $version,
            "hash_md5" => $hash_md5,
            "url_download" => $url . $pbo_path
        );
    } catch (\Throwable $th) {
        throw $th;
    }
}


function connect(): array
{
    try {
    
        return array(
            "version" => "1.0.0.2",
            "wait_ms" => 3000,
            "allowed_functions" => array("set_unit_state", "upload", "update")
        );
    } catch (\Throwable $th) {
        throw $th;
    }
}
