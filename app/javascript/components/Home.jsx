import React, { useState } from "react";
import { Link } from "react-router-dom";

export default () => {
  const [questions, setQuestions] = useState([])

  React.useEffect(() => {
    fetch('/home/load', {
      method: 'GET',
    }).then(res => res.json()).then(res => setQuestions(res.data))
  }, [])

  return (
    <>
      <h1>Home</h1>
      {questions.map((question) =>
        <div>
          <p>{question.question}</p>
          <p>{question.answer} </p>
        </div>)}
    </>
  )
}
