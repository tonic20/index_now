module IndexNow
  Result = Data.define(:urls, :error) do
    def ok? = error.nil?
  end
end
