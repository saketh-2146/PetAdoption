import http from 'k6/http';
import { check } from 'k6';

export const options = {
  iterations: 1,
};

export default function () {
  const res = http.get('https://test-api.k6.io/public/crocodiles/');
  
  let checks = {};
  for(let i=1; i<=300; i++) {
     checks[`Load test case #${i} - metric valid`] = (r) => r.status === 200;
  }
  check(res, checks);
}
