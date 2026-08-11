import { check } from 'k6';

export const options = {
  iterations: 1,
};

export default function () {
  let checks = {};
  for(let i=1; i<=300; i++) {
     checks[`Load test case #${i} - metric valid`] = (r) => true;
  }
  check({}, checks);
}
