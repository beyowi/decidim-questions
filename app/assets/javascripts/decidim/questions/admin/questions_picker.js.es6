$(() => {
  const $content = $(".picker-content"),
      pickerMore = $content.data("picker-more"),
      pickerPath = $content.data("picker-path"),
      toggleNoQuestions = () => {
        const showNoQuestions = $("#questions_list li:visible").length === 0
        $("#no_questions").toggle(showNoQuestions)
      }

  let jqxhr = null

  toggleNoQuestions()

  $(".data_picker-modal-content").on("change keyup", "#questions_filter", (event) => {
    const filter = event.target.value.toLowerCase()

    if (pickerMore) {
      if (jqxhr !== null) {
        jqxhr.abort()
      }

      $content.html("<div class='loading-spinner'></div>")
      jqxhr = $.get(`${pickerPath}?q=${filter}`, (data) => {
        $content.html(data)
        jqxhr = null
        toggleNoQuestions()
      })
    } else {
      $("#questions_list li").each((index, li) => {
        $(li).toggle(li.textContent.toLowerCase().indexOf(filter) > -1)
      })
      toggleNoQuestions()
    }
  })
})
