import './scroll'
import '../css/application.scss'

/* Theme switch */

const toggleSwitch = document.querySelector('.theme-switch input[type="checkbox"]');
const body = document.querySelector('body');

function switchTheme(e) {
  if (e.target.checked) {
    body.setAttribute('data-theme', 'dark');
  } else {
    body.setAttribute('data-theme', 'light');
  }
}

toggleSwitch.addEventListener('change', switchTheme, false);

/* Navbar links & expandable */

const navbarExpandables = document.querySelectorAll('a.expandable');

function expandItems(e) {
  const target = e.currentTarget;
  const parent = target.parentElement;
  const oldExpanded = document.querySelector('li.expanded');
  if (oldExpanded) {
    oldExpanded.classList.remove('expanded');
  }

  const anchor = parent.dataset.anchor;
  if (anchor) {
    const button = document.querySelector(`div[data-resource="${anchor}"]`)
    button.click()
  }

  parent.classList.add('expanded');
}

navbarExpandables.forEach(b => {
  b.addEventListener('click', expandItems, false);
});

/* Nested links */

function expandParent(e) {
  const target = e.currentTarget;
  let   parent = target.parentElement;

  while (parent.dataset.anchor === undefined) {
    parent = parent.parentElement;
  }

  const anchor = parent.dataset.anchor;
  if (anchor) {
    const button = document.querySelector(`div[data-resource="${anchor}"]`)
    button.click()
  }
}

document.querySelectorAll('nav ul ul a').forEach(a => a.addEventListener('click', expandParent, true));

/* Nested attributes */

function toggleChildList(e) {
  const target = e.currentTarget;
  const newContent = target.getAttribute('data-content');

  // Retrieve the <span> containing the text
  const textNode = target.lastElementChild

  // Change button element
  target.setAttribute('data-content', textNode.innerText);
  textNode.innerText = newContent;
  target.classList.toggle('child-revealed');

  // Toggle child list
  const list = target.nextElementSibling;
  list.classList.toggle('hidden');

  // Toggle list <div> as shown
  const parent = target.parentElement;
  parent.classList.toggle('list-shown');
}

const childListButtons = document.querySelectorAll('.section-list-title-child');
childListButtons.forEach(b => {
  b.addEventListener('click', toggleChildList, true)
})

/** Show buttons **/

const showButtons = document.querySelectorAll('.button-wrapper');

function expandResource(e) {
  const target  = e.currentTarget;
  const section = target.parentElement;
  const headSection = section.parentElement;
  const resource = target.dataset.resource;

  if (resource) {
    const anchor = document.querySelector(`nav li[data-anchor="${resource}"]`);
    anchor.classList.add('expanded');
  }

  headSection.classList.add('expanded');
}

showButtons.forEach(b => b.addEventListener('click', expandResource, false));

window.onload = () => {
  const hash = window.location.hash;
  if (hash.includes('-')) {
    const link = document.querySelector(`a[href="${hash}"]`);
    if (link) link.click();
  }
};
