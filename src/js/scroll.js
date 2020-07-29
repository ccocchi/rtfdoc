import throttle from 'lodash.throttle';

const sections = Array.prototype.slice.apply(
  document.querySelectorAll('section')
).filter(s => s.id.length > 0).reverse()

const node = document.querySelector('#content');

let current = null,
    currentLink = null;

function onScroll() {
  const sectionOnScreen = sections.find(s => s.offsetTop > 0 && s.offsetTop <= node.scrollTop + 100);

  if (sectionOnScreen.id !== current) {
    if (currentLink) {
      currentLink.classList.remove('current');
      if (currentLink.classList.contains('expandable')) currentLink.parentElement.classList.remove('current');
    }

    const node = document.querySelector(`nav a[href="#${sectionOnScreen.id}"]`);
    if (node) {
      node.classList.add('current');
      if (node.classList.contains('expandable')) node.parentElement.classList.add('current');
    }

    current = sectionOnScreen;
    currentLink = node;
  }
}

node.addEventListener('scroll', throttle(onScroll, 400, { leading: true }), false);
