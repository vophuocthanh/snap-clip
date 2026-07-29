// commitlint.config.js
export default {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat', // Tính năng mới
        'fix', // Sửa lỗi
        'docs', // Tài liệu
        'style', // Formatting
        'refactor', // Tái cấu trúc code
        'perf', // Cải thiện hiệu năng
        'test', // Test
        'build', // Build system
        'ci', // CI/CD
        'chore', // Công việc linh tinh
        'revert', // Hoàn tác
      ],
    ],
    'subject-case': [0], // Không bắt buộc case cho subject
  },
};
