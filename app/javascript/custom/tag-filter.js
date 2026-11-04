// Started with:
//   https://codepen.io/TessWide/pen/PQeJXW
// Added container-based scope
$(function () {
  // Tag filter
  $('.filter-controls').on('click', 'a', function (e) {
    e.preventDefault();

    const filterContainer = $(this).parents('.filter-container');

    // Cleanup filter controls
    filterContainer.find('.no-result').hide();
    filterContainer.find('.filter-search').val('');
    filterContainer.find('.filter-controls > a').addClass('ghost');
    $(this).closest('a').removeClass('ghost');

    // Filter based on class matching data-filter
    const filterValue = $(this).attr('data-filter');
    if (filterValue == 'all') {
      filterContainer.find('.filter-list .item').fadeIn('slow');
    } else {
      filterContainer
        .find('.filter-list .item')
        .not('.' + filterValue)
        .hide();
      filterContainer.find('.' + filterValue).fadeIn('slow');
    }
  });

  // Search filter
  $('.no-result').hide();

  $('.filter-search').keyup(function () {
    const filterContainer = $(this).parents('.filter-container');

    filterContainer.find('.filter-controls > a').addClass('ghost');

    const rows = filterContainer.find('.filter-list .item');

    var val =
        '^(?=.*\\b' +
        $.trim($(this).val()).split(/\s+/).join('\\b)(?=.*\\b') +
        ').*$',
      reg = RegExp(val, 'i'),
      text;

    rows
      .show()
      .filter(function () {
        text = $(this).text().replace(/\s+/g, ' ');
        return !reg.test(text);
      })
      .hide();

    var visible = filterContainer.find('.item:visible').length;

    if (visible == 0) {
      filterContainer.find('.no-result').show();
    } else {
      filterContainer.find('.no-result').hide();
    }
  });
});
