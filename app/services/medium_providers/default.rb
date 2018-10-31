module MediumProviders
  class Default < Provider
    delegate :logger, :to => :Rails

    def validate
      errors = []
      os = entity.try(:operatingsystem)
      medium = entity.try(:medium)
      arch = entity.try(:architecture)

      errors << N_("Operating system was not set for host '%{host}'") % { :host => entity } if os.nil?
      errors << N_("%{os} medium was not set for host '%{host}'") % { :host => entity, :os => os } if medium.nil?
      errors << N_("Invalid medium '%{medium}' for '%{os}'") % { :medium => medium, :os => os } unless os&.media&.include?(medium)
      errors << N_("Invalid architecture '%{arch}' for '%{os}'") % { :arch => arch, :os => os } unless os&.architectures&.include?(arch)
      errors
    end

    def medium_uri(path = "", &block)
      url ||= entity.medium.path if entity.medium.present?
      url ||= ''
      url += '/' + path unless path.empty?
      medium_vars_to_uri(url, entity.architecture.name, entity.operatingsystem, &block)
    end

    def interpolate_vars(pattern)
      medium_vars_to_uri(pattern, entity.architecture.name, entity.operatingsystem)
    end

    def unique_id
      @unique_id ||= begin
        full_uniq = super
        "#{entity.medium.name.parameterize}-#{full_uniq[1..10]}"
      end
    end

    def valid?
      entity.respond_to?(:medium) && errors.empty?
    end

    def additional_media
      return unless entity.respond_to?(:host_param) && (media = entity.host_param('additional_media'))
      parse_media(media) || []
    end

    private

    def medium_vars_to_uri(url, arch, os, &block)
      URI.parse(interpolate_medium_vars(url, arch, os, &block)).normalize
    end

    def interpolate_medium_vars(path, arch, os)
      return "" if path.empty?

      path = path.gsub('$arch', '%{arch}').
                  gsub('$major',  '%{major}').
                  gsub('$minor',  '%{minor}').
                  gsub('$version', '%{version}').
                  gsub('$release', '%{release}')

      vars = medium_vars(arch, os)
      if block_given?
        yield(vars)
      end

      path % vars
    end

    def medium_vars(arch, os)
      {
        arch: arch,
        major: os.major,
        minor: os.minor,
        version: os.minor.blank? ? os.major : [os.major, os.minor].compact.join('.'),
        release: os.release_name.presence || ''
      }
    end

    def parse_media(media)
      media = JSON.parse(media)
      if media.is_a?(Array)
        media.reject { |medium| is_invalid_hash(medium) }
      else
        logger.error("Expected #{entity.name} additional_media parameter to be an array.")
      end
    rescue JSON::ParserError
      logger.error("JSON parsing error on #{entity.name}'s additional_media parameter.")
    end

    def is_invalid_hash(medium)
      return false unless medium['name'].blank? || medium['url'].blank?
      logger.error("Medium #{medium} missing name.") if medium['name'].blank?
      logger.error("Medium #{medium} missing URL.") if medium['url'].blank?
      true
    end
  end
end
