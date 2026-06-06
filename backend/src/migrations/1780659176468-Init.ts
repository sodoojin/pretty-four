import { MigrationInterface, QueryRunner } from "typeorm";

export class Init1780659176468 implements MigrationInterface {
    name = 'Init1780659176468'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TABLE \`users\` (\`id\` uuid NOT NULL, \`email\` varchar(255) NULL, \`password\` varchar(255) NULL, \`provider\` enum ('email', 'google', 'kakao') NOT NULL DEFAULT 'email', \`providerId\` varchar(255) NULL, \`activeChildId\` varchar(255) NULL, \`createdAt\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), UNIQUE INDEX \`IDX_97672ac88f789774dd47f7c8be\` (\`email\`), PRIMARY KEY (\`id\`)) ENGINE=InnoDB`);
        await queryRunner.query(`CREATE TABLE \`children\` (\`id\` uuid NOT NULL, \`userId\` uuid NOT NULL, \`name\` varchar(255) NOT NULL, \`birthDate\` date NOT NULL, \`createdAt\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), PRIMARY KEY (\`id\`)) ENGINE=InnoDB`);
        await queryRunner.query(`CREATE TABLE \`sessions\` (\`id\` uuid NOT NULL, \`childId\` uuid NOT NULL, \`userId\` varchar(255) NOT NULL, \`audioPath\` varchar(255) NULL, \`durationSec\` int NOT NULL DEFAULT '0', \`status\` enum ('processing', 'completed', 'failed') NOT NULL DEFAULT 'processing', \`recordedAt\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), PRIMARY KEY (\`id\`)) ENGINE=InnoDB`);
        await queryRunner.query(`CREATE TABLE \`analysis_results\` (\`id\` uuid NOT NULL, \`sessionId\` uuid NOT NULL, \`summary\` json NOT NULL, \`feedbacks\` json NOT NULL, \`rawTranscript\` text NULL, \`childAgeMonths\` int NOT NULL, \`createdAt\` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6), UNIQUE INDEX \`REL_a5162b045fdd339e37c32d6de3\` (\`sessionId\`), PRIMARY KEY (\`id\`)) ENGINE=InnoDB`);
        await queryRunner.query(`ALTER TABLE \`children\` ADD CONSTRAINT \`FK_045e714a8906182cae37c8dab89\` FOREIGN KEY (\`userId\`) REFERENCES \`users\`(\`id\`) ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE \`sessions\` ADD CONSTRAINT \`FK_b6d4667a0df16f4d8f67593f215\` FOREIGN KEY (\`childId\`) REFERENCES \`children\`(\`id\`) ON DELETE NO ACTION ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE \`analysis_results\` ADD CONSTRAINT \`FK_a5162b045fdd339e37c32d6de39\` FOREIGN KEY (\`sessionId\`) REFERENCES \`sessions\`(\`id\`) ON DELETE NO ACTION ON UPDATE NO ACTION`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE \`analysis_results\` DROP FOREIGN KEY \`FK_a5162b045fdd339e37c32d6de39\``);
        await queryRunner.query(`ALTER TABLE \`sessions\` DROP FOREIGN KEY \`FK_b6d4667a0df16f4d8f67593f215\``);
        await queryRunner.query(`ALTER TABLE \`children\` DROP FOREIGN KEY \`FK_045e714a8906182cae37c8dab89\``);
        await queryRunner.query(`DROP INDEX \`REL_a5162b045fdd339e37c32d6de3\` ON \`analysis_results\``);
        await queryRunner.query(`DROP TABLE \`analysis_results\``);
        await queryRunner.query(`DROP TABLE \`sessions\``);
        await queryRunner.query(`DROP TABLE \`children\``);
        await queryRunner.query(`DROP INDEX \`IDX_97672ac88f789774dd47f7c8be\` ON \`users\``);
        await queryRunner.query(`DROP TABLE \`users\``);
    }

}
