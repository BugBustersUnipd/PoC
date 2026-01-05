# Carica la configurazione Bedrock dal file YAML con supporto ERB
# Viene memorizzata in memoria e riutilizzata per evitare ricariche
# Supporta due profili: document_analysis e text_generation

BEDROCK_CONFIG = begin
  yaml_path = Rails.root.join("config/bedrock.yml")
  yaml_content = File.read(yaml_path)

  # Processa il template ERB
  erb = ERB.new(yaml_content)
  processed_yaml = erb.result

  # Carica YAML CON gli alias abilitati (unsafe_load)
  all_config = YAML.unsafe_load(processed_yaml)

  # Ritorna la configurazione per l'ambiente corrente
  all_config[Rails.env] || all_config["development"]
end.freeze

# Costanti separate per ogni profilo (facile da riferenziare con ::)
BEDROCK_CONFIG_ANALYSIS = BEDROCK_CONFIG["document_analysis"].freeze
BEDROCK_CONFIG_GENERATION = BEDROCK_CONFIG["text_generation"].freeze
BEDROCK_CONFIG_IMAGE_GENERATION = BEDROCK_CONFIG["image_generation"].freeze
