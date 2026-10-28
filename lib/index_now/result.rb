module IndexNow
  Result = Data.define(:urls, :error, :disabled) do
    def initialize(urls: [], error: nil, disabled: false) = super

    def ok? = error.nil?

    def disabled? = disabled
  end
end
