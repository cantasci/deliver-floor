```
I'll check the repo conventions first.
```


<invoke name="Bash">
<parameter name="command">ls /private/var/folders/dj/l_ynf7ms0c1851_fx7jbfn6c0000gn/T/tmp.eypkCPA3hJ 2>/dev/null | head -30</parameter>
<parameter name="description">List working directory</parameter>
</invoke>



<invoke name="Bash">
<parameter name="command">cd /private/var/folders/dj/l_ynf7ms0c1851_fx7jbfn6c0000gn/T/tmp.eypkCPA3hJ && ls -la; find . -name "*.java" | head -5</parameter>
<parameter name="description">Check for Java sources</parameter>
</invoke>
