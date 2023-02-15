module AskQuestionModule
    def vector_similarity(x, y)
        return Vector.send(:new, x).inner_product(Vector.send(:new, y))
    end

    def order_context_by_query_similarity(question_embedding, context)
        document_similarities = Hash.new()
        context.each do |key, page|
            sim = vector_similarity(question_embedding, page[0])
            document_similarities[key] = sim
        end
        sorted_docs = document_similarities.sort_by {|k,v| v}
        return sorted_docs.reverse.to_h
    end

    def choose_sections(embedding, most_relevant_context)
        chosen_sections_len = 0
        chosen_sections = []
        chosen_sections_indexes = []    # used for understanding
        most_relevant_context.each do |key, relevance|
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

    def construct_promopt(question, embedding, question_embedding)
        most_relevant_context = order_context_by_query_similarity(question_embedding, embedding)
        chosen_sections = choose_sections(embedding, most_relevant_context)
        header = """Sahil Lavingia is the founder and CEO of Gumroad, and the author of the book The Minimalist Entrepreneur (also known as TME). These are questions and answers by him. Please keep your answers to three sentences maximum, and speak in complete sentences. Stop speaking once your point is made.\n\nContext that may be useful, pulled from The Minimalist Entrepreneur:\n"""
        prompt = header + chosen_sections.join('')  + "\n\n Q: " + question + "\n A:"
        return prompt
    end
end