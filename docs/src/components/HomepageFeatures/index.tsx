import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';
import React from "react";

type FeatureItem = {
    title: string;
    Svg?: React.ComponentType<React.ComponentProps<'svg'>>;
    description: React.JSX.Element;
    imageSrc?: string;
};

const FeatureList: FeatureItem[] = [
    {
        title: 'Easy to Use',
        imageSrc: '/img/2.png',
        description: (
            <>
                Dependy is designed to be lightweight and straightforward, making it easy to integrate into your Dart or
                Flutter projects. Get started quickly and manage your dependencies without hassle.
            </>
        ),
    },
    {
        title: 'Focus on What Matters',
        imageSrc: '/img/1.png',
        description: (
            <>
                With Dependy, you can concentrate on building your application while we handle the dependency
                management. Simply define your services and let Dependy take care of the rest.
            </>
        ),
    },
    {
        title: 'Powered by Dart',
        imageSrc: '/img/3.png',
        description: (
            <>
                Dependy leverages Dart's powerful features to provide a flexible and efficient dependency injection
                system. Customize your service registration and access them seamlessly throughout your application while
                maintaining clean and organized code.
            </>
        ),
    },
];

function Feature({title, Svg, imageSrc, description}: FeatureItem) {
    return (
        <div className={clsx('col col--4')}>
            <div className="text--center">
                {
                    imageSrc ? <img className={styles.featureSvg} src={imageSrc} role="img" alt="image-1"/> : null
                }
                {
                    Svg ? <Svg className={styles.featureSvg} role="img"/> : null
                }

            </div>
            <div className="text--center padding-horiz--md">
                <Heading as="h3">{title}</Heading>
                <p>{description}</p>
            </div>
        </div>
    );
}

export default function HomepageFeatures(): JSX.Element {
    return (
        <section className={styles.features}>
            <div className="container">
                <div className="row">
                    {FeatureList.map((props, idx) => (
                        <Feature key={idx} {...props} />
                    ))}
                </div>
            </div>
        </section>
    );
}
