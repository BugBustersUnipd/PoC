#!/usr/bin/env ruby
# Script per creare un PDF di test per l'API di analisi documenti
# Questo script crea un PDF minimale valido con contenuto di esempio

puts "Creazione PDF di test..."

# Crea un PDF minimale valido con testo di esempio
# Questo è un PDF base valido che può essere letto dall'API
pdf_content = <<~PDF_EOF
%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj
2 0 obj
<<
/Type /Pages
/Kids [3 0 R]
/Count 1
>>
endobj
3 0 obj
<<
/Type /Page
/Parent 2 0 R
/Resources <<
/Font <<
/F1 <<
/Type /Font
/Subtype /Type1
/BaseFont /Helvetica
>>
>>
>>
/MediaBox [0 0 612 792]
/Contents 4 0 R
>>
endobj
4 0 obj
<<
/Length 250
>>
stream
BT
/F1 16 Tf
72 720 Td
(DOCUMENTO DI TEST) Tj
0 -30 Td
/F1 12 Tf
(Data competenza: #{Time.now.strftime('%d/%m/%Y')}) Tj
0 -25 Td
(Codice Fiscale: ABCDEF12G34H567I) Tj
0 -25 Td
(Nome: Mario Rossi) Tj
0 -25 Td
(Azienda: Test Company SRL) Tj
0 -25 Td
(Tipo documento: Cedolino Stipendi) Tj
ET
endstream
endobj
xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000314 00000 n 
trailer
<<
/Size 5
/Root 1 0 R
>>
startxref
564
%%EOF
PDF_EOF

# Salva il PDF nella directory corrente
pdf_path = File.join(Dir.pwd, 'documento-test.pdf')
File.write(pdf_path, pdf_content)

puts "✓ PDF creato con successo!"
puts "  Percorso: #{pdf_path}"
puts ""
puts "Puoi ora usare questo file per testare l'API:"
puts "  http://localhost:3000/documentTester.html"
puts ""
puts "Il PDF contiene dati di esempio per testare l'estrazione:"
puts "  - Tipo documento: Cedolino Stipendi"
puts "  - Data competenza: #{Time.now.strftime('%d/%m/%Y')}"
puts "  - Codice Fiscale: ABCDEF12G34H567I"
puts "  - Nome: Mario Rossi"

