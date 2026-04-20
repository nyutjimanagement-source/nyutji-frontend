const { User } = require('../backend/models');

async function getMitras() {
  try {
    const mitras = await User.findAll({
      where: { role: 'ML' },
      attributes: ['id', 'name', 'registration_status']
    });
    console.log(JSON.stringify(mitras, null, 2));
    process.exit(0);
  } catch (err) {
    console.error('Error fetching mitras:', err);
    process.exit(1);
  }
}

getMitras();
