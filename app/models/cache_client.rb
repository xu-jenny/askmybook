class CacheClient
    def self.get_question(question)
        Rails.cache.read(@question)
    end
    def self.write_question(question, answer)
        Rails.cache.write(@question, answer, expires_in: 10.minutes)
    end
end
