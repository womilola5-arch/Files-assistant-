@Composable
fun FileActionCard(file: TrackedFile, onAction: (String) -> Unit) {
    Card(
        modifier = Modifier.fillMaxWidth().padding(8.dp),
        elevation = CardDefaults.cardElevation(4.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(file.name, style = MaterialTheme.typography.titleMedium)
            Text("Size: ${file.size / 1024} KB", style = MaterialTheme.typography.bodySmall)
            
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                TextButton(onClick = { onAction("ARCHIVE") }) { Text("ARCHIVE") }
                Button(
                    onClick = { onAction("DELETE") },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFD32F2F))
                ) { Text("DELETE") }
            }
        }
    }
}
