# Load and parse config files from GitHub repo
class RepoConfig
  FILE_TYPES = {
    ".yml" => "yaml",
    ".json" => "json",
  }
  HOUND_CONFIG_FILE = ".hound.yml"
  STYLE_GUIDES = %w(coffee_script ruby)

  pattr_initialize :commit

  def enabled_for?(style_guide_name)
    if style_guide_name == "ruby" && legacy_config?
      true
    else
      hound_config.detect do |language, config|
        language == style_guide_name && config && config["enabled"] == true ||
          legacy_coffee_script_config?(style_guide_name, language)
      end
    end
  end

  def for(style_guide_name)
    if style_guide_name == "ruby" && legacy_config?
      hound_config
    else
      config_file_path = config_path_for(style_guide_name)

      if config_file_path
        load_file(config_file_path)
      else
        {}
      end
    end
  end

  private

  def legacy_config?
    (hound_config.keys & STYLE_GUIDES).empty?
  end

  def legacy_coffee_script_config?(style_guide_name, language)
    language == style_guide_name.camelize
  end

  def hound_config
    @hound_config ||= begin
      content = load_file(HOUND_CONFIG_FILE)
      if content.is_a?(Hash)
        content
      else
        {}
      end
    end
  end

  def config_path_for(style_guide_name)
    hound_config[style_guide_name] &&
      hound_config[style_guide_name]["config_file"]
  end

  def load_file(file_path)
    config_file_content = commit.file_content(file_path)
    extension = File.extname(file_path)

    if config_file_content.present?
      send("parse_#{FILE_TYPES[extension]}", config_file_content)
    else
      {}
    end
  end

  def parse_yaml(content)
    YAML.load(content)
  rescue Psych::SyntaxError
    {}
  end

  def parse_json(content)
    JSON.parse(content)
  end
end
