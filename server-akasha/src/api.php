<?php
include '/db/db.php';
header("Content-Type: application/json");

$method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);


switch ($method) {
    case 'GET':
        //Chequea si la ID está presente en la URL
        if (isset($_GET['id'])) {
            $id = $_GET['id'];
            //Prepara las sentencias con PDO para evitar inyecciones SQL
            $stmt = $con->prepare("SELECT * FROM users WHERE id = ?");
            //bind_param "i" hace referencia a que hará la variable que reemplaza a "?" contiene un entero.
            $stmt->bind_param("i", $id);
            $stmt->execute();
            $result = $stmt->get_result();
            //Crea un array asociativo
            $data = $result->fetch_assoc();
            $stmt->close();
            echo json_encode($data);
        } else {
            // This is safe as there is no user input
            $result = $con->query("SELECT * FROM users");
            $users = [];
            while ($row = $result->fetch_assoc()) {
                $users[] = $row;
            }
            echo json_encode($users);
        }
        break;

    case 'POST':
        // **Vulnerability:** Your original POST query is prone to SQL injection.
        // **Fix:** Use a prepared statement.
        $name = $input['name'] ?? null;
        $email = $input['email'] ?? null;
        $age = $input['age'] ?? null;
        
        $stmt = $con->prepare("INSERT INTO users (name, email, age) VALUES (?, ?, ?)");
        $stmt->bind_param("ssi", $name, $email, $age);

        if ($stmt->execute()) {
            echo json_encode(["message" => "User added successfully"]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error adding user: " . $stmt->error]);
        }
        $stmt->close();
        break;

    case 'PUT':
        // **Vulnerability:** Your original PUT query is prone to SQL injection.
        // **Fix:** Use a prepared statement.
        $id = $_GET['id'] ?? null;
        $name = $input['name'] ?? null;
        $email = $input['email'] ?? null;
        $age = $input['age'] ?? null;
        
        $stmt = $con->prepare("UPDATE users SET name=?, email=?, age=? WHERE id=?");
        $stmt->bind_param("ssii", $name, $email, $age, $id);

        if ($stmt->execute()) {
            echo json_encode(["message" => "User updated successfully"]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error updating user: " . $stmt->error]);
        }
        $stmt->close();
        break;

    case 'DELETE':
        // **Vulnerability:** Your original DELETE query is prone to SQL injection.
        // **Fix:** Use a prepared statement.
        $id = $_GET['id'] ?? null;
        
        $stmt = $con->prepare("DELETE FROM users WHERE id=?");
        $stmt->bind_param("i", $id);

        if ($stmt->execute()) {
            echo json_encode(["message" => "User deleted successfully"]);
        } else {
            http_response_code(500);
            echo json_encode(["message" => "Error deleting user: " . $stmt->error]);
        }
        $stmt->close();
        break;

    default:
        http_response_code(405); // Method Not Allowed
        echo json_encode(["message" => "Invalid request method"]);
        break;
}

$con->close();

?>