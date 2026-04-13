<?php
$host = 'mysql';        // Your MySQL container name
$user = '';         // बदल if needed
$password = ''; // बदल if needed
$database = '';     // must exist

$conn = new mysqli($host, $user, $password, $database);

// Check connection
if ($conn->connect_error) {
    die("❌ Connection failed: " . $conn->connect_error);
}

echo "✅ Connected to MySQL successfully<br>";

// Try a simple query
$result = $conn->query("SELECT NOW() AS `current_time`");

if ($result) {
    $row = $result->fetch_assoc();
    echo "🕒 MySQL time: " . $row['current_time'] . "<br>";
} else {
    echo "❌ Query failed: " . $conn->error;
}

$conn->close();
?>

