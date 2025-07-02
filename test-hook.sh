#\!/bin/bash
echo "Hook triggered at $(date)" >> /home/schmug/disclaude/hook-test.log
echo "Working directory: $(pwd)" >> /home/schmug/disclaude/hook-test.log
echo "Input received:" >> /home/schmug/disclaude/hook-test.log
cat >> /home/schmug/disclaude/hook-test.log
echo "---" >> /home/schmug/disclaude/hook-test.log
EOF < /dev/null
