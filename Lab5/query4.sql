CREATE INDEX sal_ind on EMP(sal);

EXPLAIN PLAN FOR SELECT avg(e.sal) FROM emp e WHERE e.deptno < 10 AND e.sal > 100 AND e.sal < 200;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY());

