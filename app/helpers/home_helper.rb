module HomeHelper
    EMBEDDING_MODEL="text-embedding-ada-002"
    COMPLETIONS_MODEL = "text-davinci-003"
    MAX_SECTION_LEN = 1000

    def client() = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])

    def download_object(filename, objKey)
        p "AWS CREDENTIALS"
        p ENV['AWS_BUCKET_NAME']
        Aws.config.update(
            region: 'us-east-1',
            credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY'], ENV['AWS_SECRET_ACCESS_KEY'])
        )
        s3_client = Aws::S3::Client.new(region: 'us-east-1')
        response = s3_client.list_objects_v2(bucket: ENV['AWS_BUCKET_NAME'])
        response.contents.each do |object|
            puts object.key
        end

        s3_client.get_object(
            response_target: filename,
            bucket: ENV['AWS_BUCKET_NAME'],
            key: objKey
        )
    end

    def load_embedding_csv(filepath)
        embedding = CSV.read(filepath)
        hash = Hash.new()
        embedding.each do |page|
            hash[page[0]] = [page[1].gsub("[", "").gsub("]", "").split(/\s*,\s*/).map(&:to_f), page[2], page[3]]
        end
        return hash
    end

    def get_embedding(text, model=EMBEDDING_MODEL)
        client.embeddings(
            parameters: {
                model: model,
                input: text
            }
        )["data"][0]["embedding"]
    end

    def vector_similarity(x, y)
        return Vector.send(:new, x).inner_product(Vector.send(:new, y))
    end

    def order_document_sections_by_query_similarity(query, context)
        query_embedding = get_embedding(query, EMBEDDING_MODEL)
        document_similarities = Hash.new()
        context.each do |key, page|
            sim = vector_similarity(query_embedding, page[0])
            document_similarities[key] = sim
        end
        sorted_docs = document_similarities.sort_by {|k,v| v}
        return sorted_docs.reverse.to_h
    end

    def choose_sections(embedding, most_relevant_document_sections)
        chosen_sections_len = 0
        chosen_sections = []
        chosen_sections_indexes = []    # used for understanding
        most_relevant_document_sections.each do |key, relevance|
            chosen_sections_indexes << key
            # find embedding row by first column
            row = embedding[key]
            tokens = Integer(row[1])
            chosen_sections_len += tokens
            if chosen_sections_len >= MAX_SECTION_LEN
                break
            end
            chosen_sections << row[2]
        end
        return chosen_sections
    end

    def construct_query_promopt(embedding, question)
        most_relevant_document_sections = order_document_sections_by_query_similarity(question, embedding)
        chosen_sections = choose_sections(embedding, most_relevant_document_sections)
        header = """Sahil Lavingia is the founder and CEO of Gumroad, and the author of the book The Minimalist Entrepreneur (also known as TME). These are questions and answers by him. Please keep your answers to three sentences maximum, and speak in complete sentences. Stop speaking once your point is made.\n\nContext that may be useful, pulled from The Minimalist Entrepreneur:\n"""
        prompt = header + chosen_sections.join('')  + "\n\n Q: " + question + "\n A:"
        return prompt
    end

    def ask_question(prompt)
        return client.completions(
            parameters: {
                prompt: prompt,
                temperature: 0.0,
                max_tokens: 300,
                model: COMPLETIONS_MODEL,
            }
        )
    end

    def ask(question, embedding)
        prompt = construct_query_promopt(embedding, question)
        answer = ask_question(prompt)
        puts prompt
        return answer["choices"][0]["text"]
    end

end
